# encoding: utf-8
# frozen_string_literal: true

class ConnectRequest < ApplicationRecord
  MEETING_DURATION = 20.minutes
  MAX_QUESTIONS_LENGTH = 600

  belongs_to :connect_slot
  belongs_to :startup

  has_one :karma_point, as: :source

  scope :for_batch, -> (batch) { joins(:startup).where(startups: { batch_id: batch.id }) }
  scope :for_batch_id_in, -> (ids) { joins(:startup).where(startups: { batch_id: ids }) }
  scope :upcoming, -> { joins(:connect_slot).where('connect_slots.slot_at > ?', Time.now) }
  scope :completed, -> { joins(:connect_slot).where(status: STATUS_CONFIRMED).where('connect_slots.slot_at < ?', (Time.now - 20.minutes)) }
  scope :for_faculty, -> (faculty) { joins(:connect_slot).where(connect_slots: { faculty_id: faculty }) }

  delegate :faculty, :slot_at, to: :connect_slot

  STATUS_REQUESTED = 'requested'
  STATUS_CONFIRMED = 'confirmed'

  def self.valid_statuses
    [STATUS_REQUESTED, STATUS_CONFIRMED]
  end

  validates :connect_slot_id, presence: true, uniqueness: true
  validates :startup_id, presence: true
  validates :questions, presence: true, length: { maximum: MAX_QUESTIONS_LENGTH }
  validates :status, presence: true, inclusion: { in: valid_statuses }
  validates :rating_of_faculty, numericality: { greater_than: 0, less_than: 6 }, allow_nil: true
  validates :rating_of_team, numericality: { greater_than: 0, less_than: 6 }, allow_nil: true

  before_validation :set_status_for_nil

  def set_status_for_nil
    self.status = STATUS_REQUESTED if status.nil?
  end

  after_save :post_confirmation_tasks

  def post_confirmation_tasks
    return unless status_changed? && confirmed? && confirmed_at.blank?
    create_google_calendar_event if Rails.env.production?
    send_mails_for_confirmed
    save_confirmation_time!
    create_faculty_connect_session_rating_job
    create_faculty_connect_session_reminder_job
  end

  def save_confirmation_time!
    update!(confirmed_at: Time.now)
  end

  def create_faculty_connect_session_rating_job
    if Rails.env.production?
      FacultyConnectSessionRatingJob.set(wait_until: connect_slot.slot_at + 45.minutes).perform_later(id)
    else
      FacultyConnectSessionRatingJob.perform_later(id)
    end
  end

  def create_faculty_connect_session_reminder_job
    if Rails.env.production?
      FacultyConnectSessionReminderJob.set(wait_until: connect_slot.slot_at - 30.minutes).perform_later(id)
    else
      FacultyConnectSessionReminderJob.perform_later(id)
    end
  end

  def time_for_feedback_mail?
    (connect_slot.slot_at + 40.minutes).past? ? true : false
  end

  def unconfirmed?
    !confirmed?
  end

  def feedback_mails_sent?
    feedback_mails_sent_at.present?
  end

  def feedback_mails_sent!
    update!(feedback_mails_sent_at: Time.now)
  end

  def send_mails_for_confirmed
    FacultyMailer.connect_request_confirmed(self).deliver_later
    StartupMailer.connect_request_confirmed(self).deliver_later
  end

  def create_google_calendar_event
    google_calendar.create_event do |e|
      e.title = calendar_event_title
      e.start_time = slot_at.iso8601
      e.end_time = (slot_at + MEETING_DURATION).iso8601
      e.attendees = attendees
      e.description = calendar_event_description
      e.guests_can_invite_others = false
      e.guests_can_see_other_guests = false

      # Default visibility should be sufficient since it equals calendar's setting.
      # e.visibility = 'public'

      # Send an sms 1 day before the office hour and a pop-up message 1 hour before
      e.reminders = { 'useDefault' => false, 'overrides' => [{ 'method' => 'popup', 'minutes' => 60 }, { 'method' => 'sms', 'minutes' => (24 * 60) }] }
    end
  end

  def requested?
    status == STATUS_REQUESTED
  end

  def confirmed?
    status == STATUS_CONFIRMED
  end

  scope :requested, -> { where(status: STATUS_REQUESTED) }
  scope :confirmed, -> { where(status: STATUS_CONFIRMED) }

  def assign_karma_points(rating)
    rating = rating.to_i
    return false if rating < 3

    karma_point = KarmaPoint.find_or_initialize_by(source: self)
    karma_point.startup = startup
    karma_point.points = points_for_rating(rating)
    karma_point.activity_type = "Connect session with faculty member #{faculty.name}"
    karma_point.save!
  end

  private

  def points_for_rating(rating)
    {
      3 => 10,
      4 => 20,
      5 => 40
    }[rating]
  end

  def attendees
    [{ 'email' => faculty.email, 'displayName' => faculty.name, 'responseStatus' => 'needsAction' }] + startup.founders.map do |founder|
      {
        'email' => founder.email,
        'displayName' => founder.fullname,
        'responseStatus' => 'needsAction'
      }
    end
  end

  def calendar_event_description
    "Product: #{startup.display_name}\\n" \
    "Timeline: #{Rails.application.routes.url_helpers.startup_url(startup, host: 'https://sv.co')}\\n" \
    "Team lead: #{startup.admin.fullname}\\n\\n" \
    "Questions Asked:\\n\\n" \
    "#{questions.delete("\r").to_json[1..-2]}" # Remove \r-s and quotes introduced by to_json.
  end

  def google_calendar
    Google::Calendar.new(
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      redirect_url: ENV['GOOGLE_OAUTH_REDIRECT_URL'],
      calendar: ENV['GOOGLE_CALENDAR_ID'],
      refresh_token: ENV['GOOGLE_REFRESH_TOKEN']
    )
  end

  def calendar_event_title
    "#{startup.product_name} / #{faculty.name} (Faculty Connect)"
  end
end
