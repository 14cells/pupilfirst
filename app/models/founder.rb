# encoding: utf-8
# frozen_string_literal: true

class Founder < ApplicationRecord
  extend FriendlyId
  extend Forwardable

  include Gravtastic
  include PrivateFilenameRetrievable

  gravtastic
  acts_as_taggable

  GENDER_MALE = 'male'
  GENDER_FEMALE = 'female'
  GENDER_OTHER = 'other'

  COFOUNDER_PENDING = 'pending'
  COFOUNDER_ACCEPTED = 'accepted'
  COFOUNDER_REJECTED = 'rejected'

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :invitable, :database_authenticatable, :confirmable, :recoverable, :rememberable, :trackable, :validatable

  serialize :roles

  has_many :public_slack_messages
  has_many :requests
  belongs_to :father, class_name: 'Name'
  belongs_to :startup
  belongs_to :university
  has_many :karma_points, dependent: :destroy
  has_many :timeline_events
  has_many :visits, as: :user
  has_many :ahoy_events, class_name: 'Ahoy::Event', as: :user
  has_many :targets, dependent: :destroy, as: :assignee
  has_many :platform_feedback
  belongs_to :user
  belongs_to :college, optional: true
  has_one :batch_applicant

  scope :batched, -> { joins(:startup).merge(Startup.batched) }
  scope :for_batch_id_in, -> (ids) { joins(:startup).where(startups: { batch_id: ids }) }
  scope :not_dropped_out, -> { joins(:startup).merge(Startup.not_dropped_out) }
  scope :startup_members, -> { where 'startup_id IS NOT NULL' }
  # TODO: Do we need this anymore ?
  scope :student_entrepreneurs, -> { where.not(university_id: nil) }
  scope :missing_startups, -> { where('startup_id NOT IN (?)', Startup.pluck(:id)) }
  scope :non_founders, -> { where(startup_id: nil) }
  scope :in_batch, -> (batch) { joins(:startup).where(startups: { batch_id: batch.id }) }

  # Custom scope to allow AA to filter by intersection of tags.
  scope :ransack_tagged_with, ->(*tags) { tagged_with(tags) }

  scope :active_on_slack, -> (since, upto) { joins(:public_slack_messages).where(public_slack_messages: { created_at: since..upto }) }
  scope :active_on_web, -> (since, upto) { joins(:visits).where(visits: { started_at: since..upto }) }
  scope :inactive, lambda {
    where(exited: false).where.not(id: active_on_slack(Time.now.beginning_of_week, Time.now)).where.not(id: active_on_web(Time.now.beginning_of_week, Time.now))
  }
  scope :not_exited, -> { where.not(exited: true) }

  scope :with_email, -> (email) { where('lower(email) = ?', email.downcase) }

  def self.ransackable_scopes(_auth)
    %i(ransack_tagged_with)
  end

  def self.valid_gender_values
    [GENDER_MALE, GENDER_FEMALE, GENDER_OTHER]
  end

  validates :born_on, presence: true
  validates :gender, inclusion: { in: valid_gender_values }
  validates :email, uniqueness: true, allow_nil: true

  validate :age_more_than_18

  def age_more_than_18
    errors.add(:born_on, 'must be at least 18 years old') if born_on && born_on > 18.years.ago.end_of_year
  end

  before_validation do
    self.roll_number = nil unless university.present?

    # Remove blank roles, if any.
    roles.delete('')
  end

  friendly_id :slug_candidates, use: :slugged

  def slug_candidates
    [
      [:name],
      [:name, :id]
    ]
  end

  # Remove dashes separating slug candidates.
  def normalize_friendly_id(_string)
    super.delete '-'
  end

  def should_generate_new_friendly_id?
    name_changed? || super
  end

  # TODO: Remove this method when all instance of it being used are gone. https://trello.com/c/yh0Mkfir
  def fullname
    name
  end

  # TODO: Is this hack required?
  attr_accessor :inviter_name
  # Email is not required for an unregistered 'contact' founder.
  #
  # TODO: Possibly useless method.
  def email_required?
    !invitation_token.present?
  end

  mount_uploader :avatar, AvatarUploader
  # process_in_background :avatar

  mount_uploader :college_identification, CollegeIdentificationUploader
  process_in_background :college_identification

  mount_uploader :identification_proof, IdentificationProofUploader

  normalize_attribute :startup_id, :invitation_token, :twitter_url, :linkedin_url, :name, :slack_username, :resume_url

  before_save :capitalize_name_fragments

  def capitalize_name_fragments
    return unless name_changed?
    self.name = name.titleize
  end

  has_secure_token :auth_token

  before_validation :remove_at_symbol_from_slack_username

  def remove_at_symbol_from_slack_username
    return unless slack_username.present? && slack_username.starts_with?('@')
    self.slack_username = slack_username[1..-1]
  end

  def display_name
    name.blank? ? email : name
  end

  def name_and_email
    name + (email? ? ' (' + email + ')' : '')
  end

  def to_s
    display_name
  end

  def remove_from_startup!
    self.startup_id = nil
    self.startup_admin = nil
    save! validate: false
  end

  def self.valid_roles
    %w(product engineering design)
  end

  def roles
    super || []
  end

  # A simple flag, which returns true if the founder signed in less than 15 seconds ago.
  def just_signed_in
    return false if user.current_sign_in_at.blank?
    user.current_sign_in_at > 15.seconds.ago
  end

  def founder?
    startup.present? && startup.approved?
  end

  # The option to create connect requests is restricted to team leads of batched, approved startups.
  def can_connect?
    startup.present? && startup.approved? && startup.batched? && startup_admin?
  end

  # The option to view some info about creating connect requests is restricted to non-lead members of batched, approved startups.
  def can_view_connect?
    startup.present? && startup.approved? && startup.batched? && !startup_admin?
  end

  def pending_connect_request_for?(faculty)
    startup.connect_requests.joins(:connect_slot).where(connect_slots: { faculty_id: faculty.id }, status: ConnectRequest::STATUS_REQUESTED).exists?
  end

  # Returns data required to populate /founders/:slug
  def activity_timeline
    all_activity = karma_points.where(created_at: activity_date_range) +
      timeline_events.where(created_at: activity_date_range) +
      public_slack_messages.where(created_at: activity_date_range)

    sorted_activity = all_activity.sort_by(&:created_at)

    sorted_activity.each_with_object(blank_activity_timeline) do |activity, timeline|
      if activity.is_a? PublicSlackMessage
        add_public_slack_message_to_timeline(activity, timeline)
      elsif activity.is_a? TimelineEvent
        add_timeline_event_to_timeline(activity, timeline)
      elsif activity.is_a? KarmaPoint
        add_karma_point_to_timeline(activity, timeline)
      end
    end
  end

  # If founder is part of a batched startup, it returns batch's date range - otherwise founder creation time to 'now'.
  def activity_date_range
    (activity_timeline_start_date.beginning_of_day..activity_timeline_end_date.end_of_day)
  end

  def activity_timeline_start_date
    batch_start_date.future? ? Date.today : batch_start_date
  end

  def activity_timeline_end_date
    batch_end_date.future? ? Date.today : batch_end_date
  end

  # Returns true if any of the social URL are stored. Used on profile page.
  def social_url_present?
    [twitter_url, linkedin_url, personal_website_url, blog_url, angel_co_url, github_url, behance_url, facebook_url].any?(&:present?)
  end

  # Returns the percentage of profile completion as an integer
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def profile_completion_percentage
    score = 20 # a default score given for required fields during registration
    score += 15 if slack_user_id.present? # has a valid slack account associated
    score += 10 if skype_id.present?
    score += 15 if social_url_present? # has atleast 1 social media links
    score += 5 if communication_address.present?
    score += 10 if about.present?
    score += 10 if identification_proof.present?
    score += 15 if resume_url.present? # has uploaded resume
    score
  end

  # Return the 'next-applicable' profile completion instruction as a string
  def profile_completion_instruction
    return 'Join the SV.CO Public Slack and update your slack username!' unless slack_user_id.present?
    return 'Update your Skype Id' unless skype_id.present?
    return 'Provide at-least one of your social profiles!' unless social_url_present?
    return 'Update your communication address!' unless communication_address.present?
    return 'Write a one-liner about yourself!' unless about.present?
    return 'Upload your legal ID proof!' unless identification_proof.present?
    return 'Submit a resume to your timeline to complete your profile!' unless resume_url.present?
  end

  # Make sure a new team lead is assigned before destroying the present one
  before_destroy :assign_new_team_lead

  def assign_new_team_lead
    return unless startup_admin && startup.present?

    team_lead_candidate = startup.founders.where.not(id: id).first
    team_lead_candidate&.update!(startup_admin: true)
  end

  # Should we give the founder a tour of the founder dashboard? If so, we shouldn't give it again.
  def tour_dashboard?
    if dashboard_toured
      false
    else
      update!(dashboard_toured: true)
      true
    end
  end

  # method to return the list of active founders on slack for a given duration
  def self.active_founders_on_slack(since:, upto: Time.now, batch: Batch.current_or_last)
    Founder.not_dropped_out.not_exited.in_batch(batch).active_on_slack(since, upto).distinct
  end

  # method to return the list of active founders on web for a given duration
  def self.active_founders_on_web(since:, upto: Time.now, batch: Batch.current_or_last)
    Founder.not_dropped_out.not_exited.in_batch(batch).active_on_web(since, upto).distinct
  end

  def any_targets?
    targets.present? || startup&.targets.present?
  end

  def latest_nps
    platform_feedback.scored.order('created_at').last&.promoter_score
  end

  def promoter?
    latest_nps.present? && latest_nps > 8
  end

  def detractor?
    latest_nps.present? && latest_nps < 7
  end

  def facebook_token_available?
    fb_access_token.present? && fb_token_expires_at > Time.now
  end

  def facebook_token_valid?
    facebook_token_available? && Founders::FacebookService.new(self).token_valid?(fb_access_token)
  end

  private

  def batch_start_date
    startup.present? && startup.batch.present? ? startup.batch.start_date : created_at.to_date
  end

  def batch_end_date
    startup.present? && startup.batch.present? ? startup.batch.end_date : Date.today
  end

  def blank_activity_timeline
    start_date = activity_timeline_start_date.beginning_of_month
    end_date = activity_timeline_end_date.end_of_month

    first_day_of_each_month = (start_date..end_date).select { |d| d.day == 1 }

    first_day_of_each_month.each_with_object({}) do |first_day_of_month, blank_timeline|
      blank_timeline[first_day_of_month.strftime('%B')] = { counts: (1..WeekOfMonth.total_weeks(first_day_of_month)).each_with_object({}) { |w, o| o[w] = 0 } }
    end
  end

  def add_public_slack_message_to_timeline(activity, timeline)
    month = activity.created_at.strftime('%B')

    increment_activity_count(timeline, month, WeekOfMonth.week_of_month(activity.created_at))

    if timeline[month][:list] && timeline[month][:list].last[:type] == :public_slack_message
      timeline[month][:list].last[:count] += 1
    else
      timeline[month][:list] ||= []
      timeline[month][:list] << { type: :public_slack_message, count: 1 }
    end
  end

  def add_timeline_event_to_timeline(activity, timeline)
    month = activity.created_at.strftime('%B')

    increment_activity_count(timeline, month, WeekOfMonth.week_of_month(activity.created_at))

    timeline[month][:list] ||= []
    timeline[month][:list] << { type: :timeline_event, timeline_event: activity }
  end

  def add_karma_point_to_timeline(activity, timeline)
    month = activity.created_at.strftime('%B')

    increment_activity_count(timeline, month, WeekOfMonth.week_of_month(activity.created_at))

    timeline[month][:list] ||= []
    timeline[month][:list] << { type: :karma_point, karma_point: activity }
  end

  def increment_activity_count(timeline, month, week)
    timeline[month][:counts][week] ||= 0
    timeline[month][:counts][week] += 1
  end
end
