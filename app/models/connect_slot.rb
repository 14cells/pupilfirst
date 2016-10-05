class ConnectSlot < ApplicationRecord
  belongs_to :faculty
  has_one :connect_request

  scope :next_week, -> { where('slot_at > ? AND slot_at < ?', next_week_start, next_week_end) }
  scope :upcoming, -> { where('slot_at > ?', Time.now) }

  before_destroy :check_for_connect_request

  validates_presence_of :faculty_id, :slot_at
  validates_uniqueness_of :slot_at, scope: [:faculty_id]

  validate :faculty_must_have_email

  def faculty_must_have_email
    return if faculty&.email.present?
    errors[:faculty] << 'must have stored email address'
  end

  just_define_datetime_picker :slot_at

  # Used by AA to form label.
  def display_name
    "#{faculty.name} (#{self})"
  end

  # For select input in the form in FacultyController#index.
  def to_s
    slot_at.in_time_zone('Asia/Calcutta').strftime('%b %-d, %-I:%M %p')
  end

  # Slots that haven't been taken up by a request.
  #
  # Use optional_id to add one to the list regardless of its status.
  def self.available(optional_id: nil)
    if optional_id
      where("(id NOT in (SELECT DISTINCT(connect_slot_id) FROM connect_requests) AND slot_at > ?) OR id = #{optional_id}", Time.now)
    else
      where('id NOT in (SELECT DISTINCT(connect_slot_id) FROM connect_requests)').upcoming
    end.order('slot_at ASC')
  end

  # Available slots, 3 to 11 days from now.
  def self.available_for_founder
    available.where(slot_at: (3.days.from_now.beginning_of_day..11.days.from_now.end_of_day))
  end

  def self.next_week_start
    7.days.from_now.beginning_of_week.in_time_zone('Asia/Calcutta')
  end

  def self.next_week_end
    7.days.from_now.end_of_week.in_time_zone('Asia/Calcutta')
  end

  private

  # Allow deletion only if there is no associated connect request.
  def check_for_connect_request
    return if connect_request.blank?
    errors[:base] << 'Cannot delete connect slot that has a request associated with it'
    false
  end
end
