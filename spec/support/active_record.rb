require 'active_record'

class TestModel < ActiveRecord::Base; end

class TestLogger
  attr_reader :log_entry

  def debug?
    true
  end

  def debug(log_entry)
    @log_entry = log_entry
  end
end
