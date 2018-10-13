# frozen_string_literal: true

module RequestTagger
  class Setup
    @initialized = false

    def self.start(options = {})
      raise AlreadyStartedError, I18n.t('errors.start_once') if @initialized

      @options = options

      wrap_active_record
      wrap_http

      @initialized = true
    end

    def self.stop
      return unless @initialized

      restore_active_record
      restore_http

      @options = {}
      @initialized = false
    end

    def self.sql_tag
      "/* #{sql_tag_identifier}: #{sql_sanitize(request_id)} */"
    end

    def self.http_tag
      { field: http_tag_identifier, value: request_id }
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


      def wrap_active_record
        return unless @options.fetch(:tag_sql, true)

        @ar_magic = ActiveRecordMagic.new(active_record_connection)
        @ar_magic.wrap
      end

      def wrap_http
        return unless @options.fetch(:tag_http, true)

        @http_magic = HttpMagic.new
        @http_magic.wrap
      end

      def restore_active_record
        return unless @options.fetch(:tag_sql, true)

        @ar_magic.restore
      end

      def restore_http
        return unless @options.fetch(:tag_http, true)

        @http_magic.wrap
      end

      def sql_tag_identifier
        @options[:sql_tag_name] || 'request-id'
      end

      def http_tag_identifier
        @options[:http_tag_name] || 'X-Request-Id'
      end

      def uninitialized
        '[not initialized]'
      end

      def active_record_connection
        @options[:active_record_connection] || ActiveRecord::Base.connection
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
