class AdmissionsPolicy < ApplicationPolicy
  def screening?
    level_zero? && target_incomplete?(Target::KEY_SCREENING)
  end

  def screening_submit?
    level_zero?
  end

  def coupon_submit?
    startup = current_founder.startup
    FounderPolicy.new(user, current_founder).fee? && startup.level_zero? && startup.applied_coupon.blank?
  end

  def coupon_remove?
    startup = current_founder.startup
    FounderPolicy.new(user, current_founder).fee? && startup.level_zero? && startup.applied_coupon.present?
  end

  def team_members?
    level_zero? && target_complete?(Target::KEY_SCREENING)
  end

  def team_members_submit?
    team_members?
  end

  def team_lead?
    team_members? && !current_founder.team_lead?
  end

  def accept_invitation?
    # Authorization is handled in the controller using supplied token.
    true
  end

  private

  # User should not have completed the related target.
  def target_incomplete?(key)
    target = Target.find_by(key: key)
    target.status(current_founder) != Target::STATUS_COMPLETE
  end

  # User should have completed the prerequisite target.
  def target_complete?(key)
    target = Target.find_by(key: key)
    target.status(current_founder) == Target::STATUS_COMPLETE
  end

  def target_pending?(key)
    target = Target.find_by(key: key)
    target.pending?(current_founder)
  end

  def level
    @level ||= current_founder&.startup&.level
  end

  def level_zero?
    level&.number&.zero?
  end
end
