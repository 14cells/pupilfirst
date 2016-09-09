require File.expand_path('../boot', __FILE__)

require 'rails/all'
if Rails.env.development?
  require 'dotenv'
  Dotenv.load
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Svapp
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'New Delhi'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.i18n.enforce_available_locales = true

    Dir.glob('config/routes/*.rb').each do |file|
      config.paths['config/routes.rb'] << Rails.root.join(file)
    end

    config.cache_store = :memory_store, { size: 64.megabytes }

    # Precompile fonts.
    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')

    # Add some paths to autoload
    config.autoload_paths.push "#{Rails.root}/app/presenters", "#{Rails.root}/app/services"
  end
end
