# frozen_string_literal: true

RSpec.describe RequestTagger do
  it 'has a version number' do
    expect(RequestTagger::VERSION).not_to be nil
  end

  describe 'repeated calls to .start' do
    after { described_class.stop }

    subject do
      proc do
        described_class.start(tag_sql: false, tag_http: false)
        described_class.start(tag_sql: false, tag_http: false)
      end
    end

    it { is_expected.to raise_error(RequestTagger::AlreadyStartedError) }
  end

  describe 'integration' do
    let(:connection) { ActiveRecord::Base.connection }
    let(:ddl) { 'CREATE TABLE TEST_MODELS (TEST_COLUMN)' }

    before do
      RequestTagger::Setup.request_id = 'toto'
    end

    after do
      RequestTagger::Setup.request_id = nil
      RequestTagger.stop
    end

    context 'HTTP requests' do
      before do
        @request = stub_request(:get, 'http://example.com/')
                   .with(headers: { 'X-My-Request-Id' => 'toto' })
        RequestTagger.start(tag_sql: false, http_tag_name: 'X-My-Request-Id')
      end

      it 'injects tracking tag into headers' do
        Net::HTTP.get('example.com', '/')
        expect(@request).to have_been_requested
      end
    end

    context 'Database queries' do
      before do
        require_relative 'support/active_record.rb'

        ActiveRecord::Base.establish_connection(
          adapter: 'sqlite3', database: ':memory:'
        )
        connection.exec_query(ddl)
        RequestTagger.start(tag_http: false, sql_tag_name: 'my-request-id')
      end

      it 'injects tracking tag into ActiveRecord queries' do
        test_logger = TestLogger.new
        ActiveRecord::Base.logger = test_logger
        TestModel.all.to_a
        expect(test_logger.log_entry).to include '/* my-request-id: toto */'
      end
    end
  end
end
