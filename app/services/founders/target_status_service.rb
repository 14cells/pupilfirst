module Founders
  class TargetStatusService
    def initialize(founder)
      @founder = founder
      @level_number = founder.startup.level.number
    end

    # returns the status for a given target_id
    def status(target_id)
      statuses[target_id][:status]
    end

    # returns submitted_at for a given target_id, if applicable
    def submitted_at(target_id)
      statuses[target_id][:submitted_at]
    end

    # return number of completed targets
    def completed_targets_count
      statuses.values.select { |t| t[:status] == :complete }.count
    end

    def prerequisite_targets(target_id)
      target_ids = all_target_prerequisites[target_id]
      return [] if target_ids.blank?
      applicable_targets.where(id: target_ids).as_json(only: [:id])
    end

    private

    def startup
      @startup ||= @founder.startup
    end

    # returns status and submission date for all applicable targets
    def statuses
      @statuses ||= begin
        statuses = submitted_target_statuses.merge(unsubmitted_target_statuses)
        reconfirm_prerequisites(statuses)
      end
    end

    def submitted_target_statuses
      @submitted_target_statuses ||= begin
        # Founder events for applicable targets
        founder_events = @founder.timeline_events.where.not(target_id: nil)
          .where(target: Target.founder).where(target: applicable_targets)
          .select('DISTINCT ON(target_id) *').order('target_id, created_at DESC')

        # Startup events for applicable targets
        startup_events = @founder.startup.timeline_events.where.not(target_id: nil)
          .where(target: Target.not_founder).where(target: applicable_targets)
          .select('DISTINCT ON(target_id) *').order('target_id, created_at DESC')

        (founder_events + startup_events).each_with_object({}) do |event, result|
          result[event.target_id] = {
            status: target_status(event),
            submitted_at: event.created_at.iso8601
          }
        end
      end
    end

    # Mapping from the latest event's verification status to the associated targets completion status.
    def target_status(event)
      case event.status
        when TimelineEvent::STATUS_VERIFIED then
          Target::STATUS_COMPLETE
        when TimelineEvent::STATUS_NOT_ACCEPTED then
          Target::STATUS_NOT_ACCEPTED
        when TimelineEvent::STATUS_NEEDS_IMPROVEMENT then
          Target::STATUS_NEEDS_IMPROVEMENT
        else
          Target::STATUS_SUBMITTED
      end
    end

    def unsubmitted_target_statuses
      @unsubmitted_target_statuses ||= begin
        applicable_targets.each_with_object({}) do |target, result|
          # skip if submitted target
          next if submitted_target_statuses[target.id].present?

          result[target.id] = {
            status: unavailable_or_pending?(target),
            submitted_at: nil
          }
        end
      end
    end

    # all applicable targets for the founder
    def applicable_targets
      @applicable_targets ||= Target.live.joins(target_group: :level).where(target_groups: { level: open_levels })
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def unavailable_or_pending?(target)
      # Non-submittables are no-brainers.
      return Target::STATUS_UNAVAILABLE if target.submittability == Target::SUBMITTABILITY_NOT_SUBMITTABLE

      # So are targets in higher levels
      return Target::STATUS_LEVEL_lOCKED if target.level.number > @level_number

      # For milestone targets, ensure last levels milestones where completed
      if target.target_group.milestone? && target.level.number == @level_number
        return Target::STATUS_PENDING_MILESTONE unless previous_milestones_completed?
      end

      prerequisites_completed?(target) ? Target::STATUS_PENDING : Target::STATUS_UNAVAILABLE
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def previous_milestones_completed?
      @previous_milestones_completed ||= begin
        return true unless @level_number > 1
        previous_level = startup.school.levels.find_by(number: @level_number - 1)
        target_groups = previous_level.target_groups.where(milestone: true)
        Target.where(target_group: target_groups).all? { |target| marked_completed?(target.id) }
      end
    end

    def marked_completed?(target_id)
      status_entry = submitted_target_statuses[target_id]
      status_entry.present? && status_entry[:status].in?([Target::STATUS_COMPLETE, Target::STATUS_NEEDS_IMPROVEMENT])
    end

    def prerequisites_completed?(target)
      prerequisites = all_target_prerequisites[target.id]
      return true if prerequisites.blank?

      prerequisites.all? { |target_id| marked_completed?(target_id) }
    end

    # all target-prerequisite mappings
    def all_target_prerequisites
      @all_target_prerequisites ||= TargetPrerequisite.joins(:target, prerequisite_target: :target_group).includes(prerequisite_target: :target_group).each_with_object({}) do |target_prerequisite, mapping|
        next if target_prerequisite.prerequisite_target.archived?
        next if target_prerequisite.prerequisite_target.target_group.blank?

        mapping[target_prerequisite.target_id] ||= []
        mapping[target_prerequisite.target_id] << target_prerequisite.prerequisite_target_id
      end
    end

    # Patch to account for the edge case of submitted targets having pending pre-requisites.
    # The status in such cases is reverted to unavailable, irrespective of the available submission.
    def reconfirm_prerequisites(statuses)
      statuses.each do |target_id, _status_details|
        # Unsubmitted targets do no need correction
        next if target_id.in? unsubmitted_target_statuses.keys

        # Targets without any prerequisites at all also do not need correction
        prerequisites = all_target_prerequisites[target_id]
        next if prerequisites.blank?

        # Targets without any pending prerequisites also do not need correction
        next if prerequisites.all? { |id| marked_completed?(id) }

        statuses[target_id] = { status: Target::STATUS_UNAVAILABLE, submitted_at: nil }
      end

      statuses
    end

    def open_levels
      @open_levels ||= begin
        minimum_level_number = startup.level.number.zero? ? 0 : 1
        levels = startup.school.levels.where('levels.number >= ?', minimum_level_number)
        levels.where(unlock_on: nil).or(levels.where('unlock_on <= ?', Date.today))
      end
    end
  end
end
