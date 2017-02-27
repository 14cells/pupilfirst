# encoding: utf-8
# frozen_string_literal: true

class Resource < ApplicationRecord
  include FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]
  acts_as_taggable

  belongs_to :batch
  belongs_to :startup

  def slug_candidates
    [:title, [:title, :updated_at]]
  end

  def should_generate_new_friendly_id?
    title_changed? || super
  end

  SHARE_STATUS_PUBLIC = 'public'
  SHARE_STATUS_APPROVED = 'approved'

  def self.valid_share_statuses
    [SHARE_STATUS_PUBLIC, SHARE_STATUS_APPROVED]
  end

  validates :title, presence: true
  validates :description, presence: true
  validates :share_status, inclusion: { in: valid_share_statuses }

  validate :file_or_video_embed_must_be_present

  def file_or_video_embed_must_be_present
    return if file.present? || video_embed.present?

    errors[:base] << 'A video embed or file is required.'
  end

  mount_uploader :file, ResourceFileUploader
  mount_uploader :thumbnail, ResourceThumbnailUploader

  scope :public_resources, -> { where(share_status: SHARE_STATUS_PUBLIC).order('title') }
  # scope to search title
  scope :title_matches, -> (search_key) { where("lower(title) LIKE ?", "%#{search_key.downcase}%") }

  # Custom scope to allow AA to filter by intersection of tags.
  scope :ransack_tagged_with, ->(*tags) { tagged_with(tags) }

  def self.ransackable_scopes(_auth)
    %i(ransack_tagged_with)
  end

  delegate :content_type, to: :file

  def self.for(founder)
    if founder&.startup&.approved?
      where(
        'share_status = ? OR (share_status = ? AND batch_id IS ? AND startup_id IS ?) OR '\
        '(share_status = ? AND batch_id = ? AND startup_id IS ?) OR (share_status = ? AND startup_id = ?)',
        SHARE_STATUS_PUBLIC,
        SHARE_STATUS_APPROVED,
        nil,
        nil,
        SHARE_STATUS_APPROVED,
        founder.startup&.batch&.id,
        nil,
        SHARE_STATUS_APPROVED,
        founder.startup&.id
      ).order('title')
    else
      public_resources
    end
  end

  def for_approved?
    share_status == SHARE_STATUS_APPROVED
  end

  def stream?
    video_embed.present? || content_type.end_with?('/mp4')
  end

  def increment_downloads(user)
    update!(downloads: downloads + 1)
    if user.present?
      Users::ActivityService.new(user).create(UserActivity::ACTIVITY_TYPE_RESOURCE_DOWNLOAD, 'resource_id' => id)
    end
  end

  after_create :notify_on_slack

  # Notify on slack when a new resource is uploaded
  def notify_on_slack
    if for_approved?
      PublicSlackTalk.post_message message: new_resource_message, founders: founders_to_notify
    else
      PublicSlackTalk.post_message message: new_resource_message, channel: '#resources'
    end
  end

  # returns an array of founders who needs to be notified of the new resource
  def founders_to_notify
    if startup_id.present?
      startup.founders
    elsif batch_id.present?
      Founder.where(startup: batch.startups)
    else
      Founder.where(startup: Startup.batched_and_approved)
    end
  end

  # message to be send to slack for new resources
  def new_resource_message
    message = "*A new #{for_approved? ? 'private resource (for approved startups)' : 'public resource'}"\
    " has been uploaded to the SV.CO Startup Library*: \n"
    message += "*Title:* #{title}\n"
    message += "*Description:* #{description}\n"
    message + "*URL:* #{Rails.application.routes.url_helpers.resource_url(self, host: 'https://sv.co')}"
  end

  # ensure titles are capitalized
  before_save do
    self.title = title.titlecase(humanize: false, underscore: false)
  end
end
