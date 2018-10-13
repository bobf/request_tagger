# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :__request_tagger__set_request_id__

  private

  def __request_tagger__set_request_id__
    RequestTagger.request_id = request.headers[RequestTagger.inbound_header]
  end
end
