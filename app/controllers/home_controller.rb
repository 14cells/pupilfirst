class HomeController < ApplicationController
  def index
    @skip_container = true
    @sitewide_notice = true if %w(startupvillage.in registration).include?(params[:redirect_from])
    @hide_nav_links = false
    @instagram_images = Instagram.load_latest_images

    render layout: 'home'
  end

  def story
    @skip_container = true
    render layout: 'application_v2'
  end

  # used by the 'shortener' gem's config
  def not_found
    raise_not_found
  end

  # GET /changelog
  def changelog
    @skip_container = true
    @changelog = File.read(File.absolute_path(Rails.root.join('CHANGELOG.md')))
    render layout: 'application_v2'
  end

  # GET /tour
  def tour
    @skip_container = true
    @batches_open = Batch.open_for_applications
    render layout: 'application_v2'
  end

  # GET /policies/privacy
  def privacy
    privacy_policy = File.read(File.absolute_path(Rails.root.join('privacy_policy.md')))
    @privacy_policy_html = Kramdown::Document.new(privacy_policy).to_html.html_safe

    respond_to do |format|
      format.json { render json: { policy: @privacy_policy_html } }
      format.html { render layout: 'application_v2' }
    end
  end

  # GET /policies/terms
  def terms
    terms_of_use = File.read(File.absolute_path(Rails.root.join('terms_of_use.md')))
    @terms_of_use_html = Kramdown::Document.new(terms_of_use).to_html.html_safe

    respond_to do |format|
      format.json { render json: { policy: @terms_of_use_html } }
      format.html { render layout: 'application_v2' }
    end
  end

  protected

  def hero_text_number
    @hero_text_number ||= begin
      session[:hero_text_numbers] ||= {}.to_json
      hero_text_numbers = JSON.parse(session[:hero_text_numbers])
      key = background_image_number.to_s
      hero_text_numbers[key] ||= rand(2) + 1
      hero_text_numbers[key] += 1
      hero_text_numbers[key] = 1 if hero_text_numbers[key] > 2
      session[:hero_text_numbers] = hero_text_numbers.to_json
      hero_text_numbers[key]
    end
  end

  def background_image_number
    @background_image_number ||= begin
      session[:background_image_number] ||= rand(4) + 1
      session[:background_image_number] += 1
      session[:background_image_number] = 1 if session[:background_image_number] > 4
      session[:background_image_number]
    end
  end

  def hero_text_alignment
    @hero_text_alignment ||= begin
      {
        1 => 'center',
        2 => 'right',
        3 => 'right',
        4 => 'right',
        5 => 'center' # TODO: Note that this fifth image (SYM's) is disabled.
      }[background_image_number]
    end
  end

  helper_method :background_image_number
  helper_method :hero_text_alignment
  helper_method :hero_text_number
end
