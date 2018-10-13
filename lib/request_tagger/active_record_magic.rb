# frozen_string_literal: true

# This code is heavily inspired by RSpec's `allow_any_instance_of` and the
# RSpec source code was used as reference material during development.
# https://github.com/rspec/rspec-mocks/blob/master/lib/rspec/mocks/any_instance/recorder.rb
#
# Thanks, RSpec devs.
# https://github.com/rspec/rspec/blob/master/LICENSE.md
module RequestTagger
  class ActiveRecordMagic
    WRAPPED_METHODS = %i[exec_query execute].freeze

    def initialize(target = ActiveRecord::Base.connection)
      @target_class = target.class
    end

    def wrap
      WRAPPED_METHODS.each { |method_name| wrap_method(method_name) }
    end

    def restore
      WRAPPED_METHODS.each { |method_name| restore_method(method_name) }
    end

    private

    def wrap_method(method_name)
      copy_original_method(method_name)

      create_proxy_method(method_name)
    end

    def copy_original_method(method_name)
      alias_name = alias_for(method_name)

      @target_class.class_exec do
        # Note that [the badly-named] `alias_method` actually copies the
        # method, so we can use it like `cp` but for methods instead of files.
        alias_method alias_name, method_name
      end
    end

    def create_proxy_method(method_name)
      alias_name = alias_for(method_name)

      @target_class.__send__(:define_method, method_name) do |sql, *args|
        tag = RequestTagger::Setup.sql_tag
        tagged_sql = "/* #{tag} */ #{sql}"
        __send__(alias_name, tagged_sql, *args)
      end
    end

    def restore_method(method_name)
      alias_name = alias_for(method_name)
      @target_class.class_exec do
        remove_method method_name
        alias_method method_name, alias_name
        remove_method alias_name
      end
    end

    def alias_for(method_name)
      :"__request_tagger_original__#{method_name}__"
    end
  end
end
