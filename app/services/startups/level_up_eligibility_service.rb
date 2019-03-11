module Startups
  # This service should be used to check whether a startup is eligible to _level up_ - to move up a level in the main
  # program - it does this by checking whether all milestone targets have been completed.
  class LevelUpEligibilityService
    def initialize(startup, founder)
      @startup = startup
      @founder = founder
      @cofounders_pending = false
    end

    ELIGIBILITY_ELIGIBLE = -'eligible'
    ELIGIBILITY_NOT_ELIGIBLE = -'not_eligible'
    ELIGIBILITY_COFOUNDERS_PENDING = -'cofounders_pending'
    ELIGIBILITY_DATE_LOCKED = -'date_locked'

    ELIGIBLE_STATUSES = [
      Targets::StatusService::STATUS_SUBMITTED,
      Targets::StatusService::STATUS_PASSED
    ].freeze

    def eligible?
      eligibility == ELIGIBILITY_ELIGIBLE
    end

    def eligibility
      @eligibility ||= begin
        if milestone_targets.any?
          all_targets_attempted = milestone_targets.all? do |target|
            target_attempted?(target)
          end

          if all_targets_attempted
            return ELIGIBILITY_COFOUNDERS_PENDING if @cofounders_pending

            return ELIGIBILITY_DATE_LOCKED if next_level_unlock_date&.future?

            return ELIGIBILITY_ELIGIBLE
          end
        end

        ELIGIBILITY_NOT_ELIGIBLE
      end
    end

    def next_level_unlock_date
      @next_level_unlock_date ||= begin
        next_level = current_level.course.levels.find_by(number: current_level.number + 1)
        next_level&.unlock_on
      end
    end

    private

    def milestone_targets
      milestone_groups = current_level.target_groups.where(milestone: true)

      return Target.none if milestone_groups.empty?

      Target.where(target_group: milestone_groups).where(archived: false)
    end

    def target_attempted?(target)
      if target.founder_role?
        completed_founders = @startup.founders.all.select do |startup_founder|
          target.status(startup_founder).in? ELIGIBLE_STATUSES
        end

        if @founder.in?(completed_founders)
          # Mark that some co-founders haven't yet completed target if applicable.
          @cofounders_pending = completed_founders.count != @startup.founders.count

          # Founder has completed this target.
          true
        else
          false
        end
      else
        Targets::StatusService.new(target, @founder).status.in? ELIGIBLE_STATUSES
      end
    end

    def current_level
      @current_level ||= @startup.level
    end
  end
end
