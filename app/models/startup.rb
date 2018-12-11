# frozen_string_literal: true

class Startup < ApplicationRecord
  include FriendlyId
  include PrivateFilenameRetrievable
  acts_as_taggable

  # For an explanation of these legacy values, see linked trello card.
  #
  # @see https://trello.com/c/SzqE6l8U
  LEGACY_STARTUPS_COUNT = 849
  LEGACY_INCUBATION_REQUESTS = 5281

  REGISTRATION_TYPE_PRIVATE_LIMITED = 'private_limited'
  REGISTRATION_TYPE_PARTNERSHIP = 'partnership'
  REGISTRATION_TYPE_LLP = 'llp' # Limited Liability Partnership

  MAX_PITCH_CHARACTERS = 140 unless defined?(MAX_PITCH_CHARACTERS)
  MAX_PRODUCT_DESCRIPTION_CHARACTERS = 150
  MAX_CATEGORY_COUNT = 3

  ADMISSION_STAGE_SIGNED_UP = 'Signed Up'
  ADMISSION_STAGE_SELF_EVALUATION_COMPLETED = 'Self Evaluation Completed'
  ADMISSION_STAGE_R1_TASK_PASSED = 'Round 1 Task Passed'
  ADMISSION_STAGE_R2_TASK_PASSED = 'Round 2 Task Passed'
  ADMISSION_STAGE_INTERVIEW_PASSED = 'Interview Passed'
  ADMISSION_STAGE_PAYMENT_INITIATED = 'Payment Initiated'
  ADMISSION_STAGE_FEE_PAID = 'Initial Payment Completed'
  ADMISSION_STAGE_ADMITTED = 'Admitted'

  # agreement duration in years
  AGREEMENT_DURATION = 5

  COURSE_FEE = 50_000

  def self.valid_registration_types
    [REGISTRATION_TYPE_PRIVATE_LIMITED, REGISTRATION_TYPE_PARTNERSHIP, REGISTRATION_TYPE_LLP]
  end

  scope :admitted, -> { joins(:level).where('levels.number > ?', 0) }
  scope :level_zero, -> { joins(:level).where(levels: { number: 0 }) }
  scope :approved, -> { where.not(dropped_out: true) }
  scope :dropped_out, -> { where(dropped_out: true) }
  scope :not_dropped_out, -> { where.not(dropped_out: true) }
  scope :agreement_signed, -> { where 'agreement_signed_at IS NOT NULL' }
  scope :agreement_live, -> { where('agreement_signed_at > ?', AGREEMENT_DURATION.years.ago) }
  scope :agreement_expired, -> { where('agreement_signed_at < ?', AGREEMENT_DURATION.years.ago) }

  # Custom scope to allow AA to filter by intersection of tags.
  scope :ransack_tagged_with, ->(*tags) { tagged_with(tags) }

  def self.ransackable_scopes(_auth)
    %i[ransack_tagged_with]
  end

  # Returns the latest verified timeline event that has an image attached to it.
  #
  # Do not return private events!
  #
  # @return TimelineEvent
  def showcase_timeline_event
    timeline_events.verified.order('event_on DESC').detect do |timeline_event|
      !timeline_event.founder_event?
    end
  end

  # Returns startups that have accrued no karma points for last week (starting monday). If supplied a date, it
  # calculates for week bounded by that date.
  def self.inactive_for_week(date: 1.week.ago)
    date = date.in_time_zone('Asia/Calcutta')

    # First, find everyone who doesn't fit the criteria.
    startups_with_karma_ids = joins(:karma_points)
      .where(karma_points: { created_at: (date.beginning_of_week + 18.hours)..(date.end_of_week + 18.hours) })
      .pluck(:id)

    # Filter them out.
    approved.admitted.not_dropped_out.where.not(id: startups_with_karma_ids)
  end

  def self.endangered
    startups_with_karma_ids = joins(:karma_points)
      .where(karma_points: { created_at: 3.weeks.ago..Time.now })
      .pluck(:id)
    approved.admitted.not_dropped_out.where.not(id: startups_with_karma_ids)
  end

  # Find all by specific category.
  def self.startup_category(category)
    joins(:startup_categories).where(startup_categories: { id: category.id })
  end

  has_many :founders, dependent: :restrict_with_error
  has_many :invited_founders, class_name: 'Founder', foreign_key: 'invited_startup_id', inverse_of: :invited_startup, dependent: :restrict_with_error

  has_and_belongs_to_many :startup_categories do
    def <<(_category)
      raise 'Use startup_categories= to enforce startup category limit'
    end
  end

  has_many :startup_feedback, dependent: :destroy
  has_many :karma_points, dependent: :restrict_with_exception
  has_many :connect_requests, dependent: :destroy

  belongs_to :level
  has_one :course, through: :level
  has_many :payments, dependent: :restrict_with_error
  has_many :archived_payments, class_name: 'Payment', foreign_key: 'original_startup_id', dependent: :nullify, inverse_of: :original_startup

  has_one :coupon_usage, dependent: :destroy
  has_one :applied_coupon, through: :coupon_usage, source: :coupon

  has_many :weekly_karma_points, dependent: :destroy
  has_many :resources, dependent: :destroy
  belongs_to :team_lead, class_name: 'Founder', optional: true
  belongs_to :billing_state, class_name: 'State', optional: true
  has_and_belongs_to_many :faculty

  # use the old name attribute as an alias for legal_registered_name
  alias_attribute :name, :legal_registered_name

  # TODO: probable stale attribute
  attr_reader :validate_registration_type

  # Friendly ID!
  friendly_id :slug_candidates, use: :slugged

  validates :slug, format: { with: /\A[a-z0-9\-_]+\z/i }, allow_nil: true
  validates :product_name, presence: true

  # TODO: probably stale
  validates :registration_type, presence: true, if: ->(startup) { startup.validate_registration_type }
  validates :registration_type, inclusion: { in: valid_registration_types }, allow_nil: true

  # PIN Code is always 6 digits
  validates :pin, numericality: { greater_than_or_equal_to: 100_000, less_than_or_equal_to: 999_999 }, allow_nil: true

  validates :product_description, length: { maximum: MAX_PRODUCT_DESCRIPTION_CHARACTERS, message: "must be within #{MAX_PRODUCT_DESCRIPTION_CHARACTERS} characters" }

  validates :pitch, length: { maximum: MAX_PITCH_CHARACTERS, message: "must be within #{MAX_PITCH_CHARACTERS} characters" }

  validates :level, presence: true

  # New set of validations for incubation wizard
  store :metadata, accessors: [:updated_from]

  before_validation do
    # Set registration_type to nil if its set as blank from backend.
    self.registration_type = nil if registration_type.blank?

    # If supplied \r\n for line breaks, replace those with just \n so that length validation works.
    self.product_description = product_description.gsub("\r\n", "\n") if product_description

    # Default product name to 'Untitled Product' if absent
    self.product_name ||= 'Untitled Product'
  end

  before_destroy do
    # Clear out associations from associated Founders (and pending ones).
    Founder.where(startup_id: id).update_all(startup_id: nil) # rubocop:disable Rails/SkipsModelValidations
  end

  after_create :regenerate_slug

  def approved?
    dropped_out != true
  end

  def dropped_out?
    dropped_out == true
  end

  mount_uploader :logo, LogoUploader
  mount_uploader :partnership_deed, PartnershipDeedUploader
  process_in_background :logo

  normalize_attribute :pitch, :product_description, :email, :phone

  normalize_attribute :website do |value|
    case value
      when '' then
        nil
      when nil then
        nil
      when %r{^https?://.*} then
        value
      else
        "http://#{value}"
    end
  end

  normalize_attribute :twitter_link do |value|
    case value
      when %r{^https?://(www\.)?twitter.com.*} then
        value
      when /^(www\.)?twitter\.com.*/ then
        "https://#{value}"
      when '' then
        nil
      when nil then
        nil
      else
        "https://twitter.com/#{value}"
    end
  end

  normalize_attribute :facebook_link do |value|
    case value
      when %r{^https?://(www\.)?facebook.com.*} then
        value
      when /^(www\.)?facebook\.com.*/ then
        "https://#{value}"
      when '' then
        nil
      when nil then
        nil
      else
        "https://facebook.com/#{value}"
    end
  end

  def founder_ids=(list_of_ids)
    founders_list = Founder.find(list_of_ids.map(&:to_i).select { |e| e.is_a?(Integer) && e.positive? })
    founders_list.each { |u| founders << u }
  end

  validate :category_count

  def category_count
    return unless @category_count_exceeded || startup_categories.count > MAX_CATEGORY_COUNT

    errors.add(:startup_categories, "Can't have more than 3 categories")
  end

  # Custom setter for startup categories.
  #
  # @param [String, Array] category_entries Array of Categories or comma-separated Category ID-s.
  def startup_categories=(category_entries)
    parsed_categories = if category_entries.is_a? String
      category_entries.split(',').map do |category_id|
        StartupCategory.find(category_id)
      end
    else
      category_entries
    end

    # Enforce maximum count for categories.
    if parsed_categories.count > MAX_CATEGORY_COUNT
      @category_count_exceeded = true
    else
      super parsed_categories
    end
  end

  def self.current_startups_split
    {
      'Approved' => approved.count,
      'Dropped-out' => dropped_out.count
    }
  end

  def agreement_live?
    agreement_signed_at.present? ? agreement_signed_at > AGREEMENT_DURATION.years.ago : false
  end

  def founder?(founder)
    return false unless founder

    founder.startup_id == id
  end

  def possible_founders
    founders + Founder.non_founders
  end

  def phone
    team_lead.try(:phone)
  end

  def cofounders(founder)
    founders - [founder]
  end

  def regenerate_slug
    update_attribute(:slug, nil) # rubocop:disable Rails/SkipsModelValidations
    save!
  end

  def should_generate_new_friendly_id?
    new_record? || slug.nil?
  end

  # Try building a slug based on the following fields in
  # increasing order of specificity.
  def slug_candidates
    name = product_name.parameterize
    [
      name,
      [name, :id]
    ]
  end

  ####
  # Temporary mentor and investor checks which always return false
  ####
  def mentors?
    false
  end

  def investors?
    false
  end

  # returns the date of the earliest verified timeline entry
  def earliest_team_event_date
    timeline_events.where.not(passed_at: nil).not_private.order(:event_on).first.try(:event_on)
  end

  # returns the date of the latest verified timeline entry
  def latest_team_event_date
    timeline_events.where.not(passed_at: nil).not_private.order(:event_on).last.try(:event_on)
  end

  def timeline_verified?
    approved? && timeline_events.joins(:timeline_event_grades).exists?
  end

  def timeline_events_for_display(viewer)
    events_for_display = timeline_events

    # Only display verified of needs-improvement events if 'viewer' is not a member of this startup.
    if viewer&.startup != self
      events_for_display = events_for_display.where.not(passed_at: nil)
    end

    decorated_events = events_for_display.includes(:target, :timeline_event_files).order(:event_on, :updated_at).reverse_order.decorate

    # Hide founder events from everyone other than author of event.
    decorated_events.reject { |event| event.hidden_from?(viewer) }
  end

  def display_name
    label = product_name
    label += " (#{name})" if name.present?
    label
  end

  def name_with_team_lead
    label = product_name
    label += " (#{team_lead.name})" if team_lead.present?
    label
  end

  def billing_founders_count
    @billing_founders_count ||= founders.not_exited.count + invited_founders.count
  end

  def present_week_number
    return nil if level.number.zero?
    return 1 if Date.today == program_started_on

    days_elapsed = (Date.today - program_started_on)
    weeks_elapsed = days_elapsed.to_f / 7

    # Let's round up.
    weeks_elapsed.ceil
  end

  def week_percentage
    if present_week_number >= 24
      100
    else
      ((present_week_number.to_f / 24) * 100).to_i
    end
  end

  def level_zero?
    level.number.zero?
  end

  def eligible_to_connect?(faculty)
    Startups::ConnectRequestEligibilityService.new(self, faculty).eligible?
  end

  def subscription_active?
    level.course.sponsored || payments.where('billing_end_at > ?', Time.now).paid.exists?
  end

  def self.admission_stages
    [ADMISSION_STAGE_SIGNED_UP, ADMISSION_STAGE_SELF_EVALUATION_COMPLETED, ADMISSION_STAGE_R1_TASK_PASSED, ADMISSION_STAGE_R2_TASK_PASSED, ADMISSION_STAGE_INTERVIEW_PASSED, ADMISSION_STAGE_FEE_PAID, ADMISSION_STAGE_ADMITTED].freeze
  end

  def active_payment
    payments.paid.order(:billing_end_at).last
  end

  def subscription_end_date
    active_payment&.billing_end_at
  end

  def timeline_events
    TimelineEvent.joins(:timeline_event_owners).where(timeline_event_owners: { founder: founders })
  end
end
