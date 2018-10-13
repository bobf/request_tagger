# frozen_string_literal: true

RSpec.describe RequestTagger::HttpMagic do
  let(:http_magic) { described_class.new }
  let(:http_tag) { { field: 'X-Request-Id', value: 'toto' } }

  before do
    allow(RequestTagger::Setup).to receive(:http_tag).and_return(http_tag)

    @wrapped_request = stub_request(:get, 'http://example.com/')
                       .with(headers: { http_tag[:field] => http_tag[:value] })

    @unwrapped_request = stub_request(:get, 'http://example.com/')
  end

  subject { http_magic }

  it { is_expected.to be_a described_class }

  describe '#wrap' do
    before { http_magic.wrap }
    after { http_magic.restore }

    it 'injects tracking header into Net::HTTP requests' do
      Net::HTTP.get('example.com', '/')
      expect(@wrapped_request).to have_been_requested
    end
  end

  describe '#restore' do
    before do
      http_magic.wrap
      http_magic.restore
    end

    it 'does not inject tracking header into Net::HTTP requests' do
      Net::HTTP.get('example.com', '/')
      expect(@unwrapped_request).to have_been_requested
    end
  end
end
