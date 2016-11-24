module StartupsHelper
  def registration_type_html(registration_type)
    case registration_type
      when Startup::REGISTRATION_TYPE_PARTNERSHIP
        'Partnership'
      when Startup::REGISTRATION_TYPE_PRIVATE_LIMITED
        'Private Limited'
      when Startup::REGISTRATION_TYPE_LLP
        'Limited Liability Partnership'
      else
        '<em>Not Registered</em>'.html_safe
    end
  end

  def stage_link(stage)
    text = TimelineEventType::STAGE_NAMES[stage]
    link = TimelineEventType::STAGE_LINKS[stage]

    link_to link, target: '_blank' do
      "#{text} <i class='fa fa-external-link'></i>".html_safe
    end
  end

  def truncated_founder_name(name)
    truncate name, length: 20, separator: ' ', omission: ''
  end

  def showcase_events_for_batch(batch)
    processed_startups = []
    showcase_events_startups = []

    batch.startups.approved
      .joins(:timeline_events).merge(TimelineEvent.verified)
      .order('timeline_events.event_on ASC').each do |startup|
      next if processed_startups.include? startup.id
      showcase_events_startups << [startup.showcase_timeline_event, startup]
      processed_startups << startup.id
    end

    showcase_events_startups
  end

  def extra_links_present?(startup)
    startup.website.present? ||
      startup.wireframe_link.present? ||
      startup.prototype_link.present? ||
      startup.facebook_link.present? ||
      startup.twitter_link.present?
  end

  def needs_improvement_tooltip_text(event)
    if current_founder && @startup.founder?(current_founder)
      needs_improvement_tooltip_for_founder(event)
    else
      needs_improvement_tooltip_for_public(event)
    end
  end

  def needs_improvement_tooltip_for_founder(event)
    if event.improved_timeline_event.present?
      I18n.t('startup.show.timeline_cards.improved_later.tooltip_text.founder')
    else
      I18n.t('startup.show.timeline_cards.needs_imprvement.tooltip_text.founder')
    end
  end

  def needs_improvement_tooltip_for_public(event)
    if event.improved_timeline_event.present?
      I18n.t('startup.show.timeline_cards.improved_later.tooltip_text.public')
    else
      I18n.t('startup.show.timeline_cards.needs_imprvement.tooltip_text.public')
    end
  end

  def needs_improvement_status_text(event)
    if event.improved_timeline_event.present?
      I18n.t('startup.show.timeline_cards.improved_later.status_text')
    else
      I18n.t('startup.show.timeline_cards.needs_imprvement.status_text')
    end
  end
end
