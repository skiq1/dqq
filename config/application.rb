require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Teleinf
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])


    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Europe/Warsaw"
    # config.eager_load_paths << Rails.root.join("extras")

    config.register_pin = "2137"

    config.analytics_url = ENV["ANALYTICS_URL"]
    config.analytics_token = ENV["ANALYTICS_TOKEN"]

    config.github_repo_name = ENV["GITHUB_REPO_NAME"]
    config.github_api_token = ENV["REPO_API_TOKEN"]
  end
end
