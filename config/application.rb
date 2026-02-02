# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'
require 'aws-sdk-core'

Bundler.require(*Rails.groups)

module Animeon
  DOMAINS = {
    production: 'animeon.ru',
    development: 'animeon.ru',
  }.freeze
  DOMAIN = DOMAINS[Rails.env.to_sym]
  PROTOCOLS = {
    production: 'https',
    development: 'https'
  }.freeze
  PROTOCOL = ENV['IS_LOCAL_RUN'] ? 'https' : PROTOCOLS[Rails.env.to_sym]

  HOST = "#{Animeon::PROTOCOL}://#{Animeon::DOMAIN}".freeze
  PROXY_SUBDOMAIN = 'proxy'
  PROXY = "#{Animeon::PROTOCOL}://#{Animeon::PROXY_SUBDOMAIN}.#{Animeon::DOMAIN}".freeze
  class Application < Rails::Application
    unless Rails.env.test?
      require 'prometheus_exporter/middleware'

      # This reports stats per request like HTTP status and timings
      Rails.application.middleware.unshift PrometheusExporter::Middleware
    end
    def shiki_api
      Shikimori::API::Client.new('https://shiki.one/')
    end
    def redis
      Rails.application.config.redis
    end
    Aws.config.update(
      credentials: Aws::Credentials.new(ENV['ACCESS_KEY_ID'], ENV['SECRET_ACCESS_KEY']),
      region: ENV['S3_REGION'],
      endpoint: ENV['S3_ENDPOINT'],
      force_path_style: true,
      signature_version: 'v4'
    )
    Aws.config.update(logger: Logger.new($stdout), log_level: :debug)
    def s3_client
      Aws::S3::Client.new
    end
    config.i18n.default_locale = :ru
    config.i18n.locale = :ru
    config.i18n.available_locales = %i[ru en]
    config.load_defaults 7.1
    config.autoload_paths << "#{config.root}/app/*"
    config.autoload_lib(ignore: %w[assets tasks])
    config.generators do |generator|
      generator.template_engine :slim
      generator.stylesheets false
      generator.helper false
      generator.helper_specs false
      generator.view_specs false
      generator.test_framework :rspec
    end
    config.redis = Redis.new(
      host: Rails.env == 'production' ? 'redis' : 'localhost',
      port: 6379,
      #password: ENV['REDIS_PASSWORD']
    )
  end
end
