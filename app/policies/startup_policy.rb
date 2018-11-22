class StartupPolicy < ApplicationPolicy
  def show?
    record.level.number.positive?
  end

  def timeline_event_show?(timeline_event)
    return false if timeline_event.blank?

    if timeline_event.founder_event?
      # Show founder events only to the founder who posted it.
      timeline_event.founder.present? && timeline_event.founder == current_founder
    else
      # Show verified events to everyone, and non-verified events to startup founders.
      return true if timeline_event.passed_at?

      timeline_event.startup.present? && timeline_event.startup == current_founder&.startup
    end
  end

  def update?
    # Can't see? Can't update.
    return false unless show?

    # User's startup must be 'this' one.
    return false unless user&.current_founder&.startup == record

    # Founder's subscription must be active, and he must not have existed.
    current_founder.subscription_active? && !current_founder.exited?
  end

  def edit?
    update?
  end

  def level_up?
    if record.level.number.positive?
      # If level 1 or above, user must be able to update to level up.
      return false unless update?
    end

    Startups::LevelUpEligibilityService.new(record, current_founder).eligible?
  end

  def billing?
    record.level.number.positive? && !record.level.school.sponsored? # Only startups in schools that are not sponsored needs a billing page.
  end
end
