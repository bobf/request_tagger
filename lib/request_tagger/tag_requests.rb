# frozen_string_literal: true

module RequestTagger
  module TagRequests
    extend ActiveSupport::Concern

    included do
      before_action :__request_tagger__set_request_id__
    end

    private

    def __request_tagger__set_request_id__
      field = RequestTagger::Setup.inbound_header
      RequestTagger::Setup.request_id = request.headers[field]
    end
  end
end
