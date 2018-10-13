# frozen_string_literal: true

require 'i18n'

require 'request_tagger/version'
require 'request_tagger/errors'
require 'request_tagger/setup'
require 'request_tagger/active_record_magic'
require 'request_tagger/http_magic'

module RequestTagger
  def self.start(options = {})
    Setup.start(options)
  end

  def self.stop
    Setup.stop
  end
end

locales_path = File.expand_path('../locales/*.yml', __dir__)

I18n.load_path += Dir[locales_path]

# Avoid i18n conflicts when using as a gem in a Rails application
unless Gem.loaded_specs.key?('rails')
  I18n.backend.load_translations
  I18n.config.available_locales = :en
end

require 'request_tagger/rails' if Gem.loaded_specs.key?('rails')
