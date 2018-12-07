module ActiveAdmin
  module ActiveAdminHelper
    def sv_id_link(founder)
      if founder.present?
        link_to "#{founder.email} - #{founder.fullname} #{founder.phone.present? ? "(#{founder.phone}" : ''})", admin_founder_path(founder)
      else
        '<em>Missing, probably deleted.</em>'.html_safe
      end
    end

    def founders_by_karma(level:, week_starting_at:)
      week_end_date = week_starting_at + 1.week
      Founder.joins(:startup, :karma_points)
        .where(startups: { level_id: level.id })
        .where(karma_points: { created_at: (week_starting_at..week_end_date) })
        .group(:founder_id)
        .sum(:points)
        .sort_by { |_founder_id, points| points }.reverse
    end

    # Returns links to tags separated by a separator string.
    def linked_tags(tags, separator: ', ')
      return if tags.blank?

      tags.map do |tag|
        link_to tag.name, admin_tag_path(tag)
      end.join(separator).html_safe
    end

    # Return a string explaining details of reaction received on public slack
    def reaction_details(message)
      reaction_to_author = message.reaction_to.founder.present? ? message.reaction_to.founder.fullname : message.reaction_to.slack_username
      "reacted with #{message.body} to \'#{truncate(message.reaction_to.body, length: 250)}\' from #{reaction_to_author}"
    end

    def commitment_options
      {
        'Part Time' => Faculty::COMMITMENT_PART_TIME,
        'Full Time' => Faculty::COMMITMENT_FULL_TIME
      }
    end

    def none_one_or_many(view, resources)
      return unless resources.exists?

      if resources.count > 1
        view.ul do
          resources.each do |resource|
            view.li do
              yield(resource)
            end
          end
        end
      else
        yield(resources.first)
      end
    end
  end
end
