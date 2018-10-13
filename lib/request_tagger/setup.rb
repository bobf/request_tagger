# frozen_string_literal: true

module RequestTagger
  class Setup
    @initialized = false

    def self.start(options = {})
      raise AlreadyStartedError, I18n.t('errors.start_once') if @initialized

      @ar_magic = ActiveRecordMagic.new(active_record_connection(options))
      @http_magic = HttpMagic.new

      @initialized = true
    end

    def self.stop
      return unless @initialized

      @ar_magic.restore

      @initialized = false
    end

    def self.sql_tag
      "/* #{tag_identifier}: #{sql_sanitize(request_id)} */"
    end

    def self.http_tag
      { field: 'X-Request-Id', value: request_id }
    end

    def self.request_id=(val)
      # I would prefer not to use `Thread.current` for storage but, since we
      # can't control what kind of Rails server is in use, we don't have much
      # choice.
      Thread.current[:__request_tagger__request_id__] = val
    end

    def self.request_id
      Thread.current[:__request_tagger__request_id__] || uninitialized
    end

    class << self
      private

      def tag_identifier
        'request-id'
      end

      def uninitialized
        '[not initialized]'
      end

      def active_record_connection(options)
        options[:active_record_connection] || ActiveRecord::Base.connection
      end

      def sql_sanitize(val)
        val.chars.select { |char| sql_whitelist.include?(char) }.join
      end

      def sql_whitelist
        # It could be enough to just blacklist '*' but I'd rather be extra
        # cautious here.
        alphanum = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
        alphanum + %w[[ ] { } ( ) _ -] + [' ']
      end
    end
  end
end
