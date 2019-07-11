class User < ApplicationRecord
  has_many :founders, dependent: :restrict_with_error
  has_one :admin_user, dependent: :restrict_with_error
  has_many :faculty, dependent: :restrict_with_error
  has_many :user_activities, dependent: :destroy
  has_many :visits, as: :user, dependent: :destroy, inverse_of: :user
  has_many :school_admins, dependent: :restrict_with_error
  has_many :user_profiles, dependent: :restrict_with_error

  has_secure_token :login_token

  # database_authenticable is required by devise_for to generate the session routes
  devise :database_authenticatable, :trackable, :rememberable, :omniauthable,
    omniauth_providers: %i[google_oauth2 facebook github]

  normalize_attribute :name, :gender, :phone, :communication_address, :title, :key_skills, :about,
    :resume_url, :blog_url, :personal_website_url, :linkedin_url, :twitter_url, :facebook_url,
    :angel_co_url, :github_url, :behance_url, :skype_id

  validates :email, presence: true, uniqueness: true, email: true
  has_one_attached :avatar

  def self.with_email(email)
    where('lower(email) = ?', email.downcase).first # rubocop:disable Rails/FindBy
  end

  GENDER_MALE = 'male'.freeze
  GENDER_FEMALE = 'female'.freeze
  GENDER_OTHER = 'other'.freeze

  def self.valid_gender_values
    [GENDER_MALE, GENDER_FEMALE, GENDER_OTHER]
  end

  validates :gender, inclusion: { in: valid_gender_values }, allow_nil: true

  before_save :capitalize_name_fragments

  def capitalize_name_fragments
    return unless name_changed?

    self.name = name.split.map do |name_fragment|
      name_fragment[0] = name_fragment[0].capitalize
      name_fragment
    end.join(' ')
  end

  def email_bounced?
    email_bounced_at.present?
  end

  # True if the user has ever signed in, handled by Users::ConfirmationService.
  def confirmed?
    confirmed_at.present?
  end

  def admin?
    admin_user.present?
  end

  def display_name
    email
  end

  def avatar_variant(version)
    case version
      when :mid
        avatar.variant(combine_options:
          {
            auto_orient: true,
            gravity: "center",
            resize: '200x200^',
            crop: '200x200+0+0'
          })
      when :thumb
        avatar.variant(combine_options:
          {
            auto_orient: true,
            gravity: 'center',
            resize: '50x50^',
            crop: '50x50+0+0'
          })
      else
        avatar
    end
  end

  def initials_avatar(background_shape: nil)
    logo = Scarf::InitialAvatar.new(name, background_shape: background_shape)
    "data:image/svg+xml;base64,#{Base64.encode64(logo.svg)}"
  end
end
