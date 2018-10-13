# frozen_string_literal: true

RSpec.describe RequestTagger::Setup do
  let(:setup) { described_class.new }
  let(:not_initialized) { '[not initialized]' }
  let(:start_params) { { tag_sql: false, tag_http: false } }

  subject { setup }

  it { is_expected.to be_a described_class }

  describe '.start' do
    subject { described_class.start(start_params) }
    after { described_class.stop }

    it { is_expected.to be true }
  end

  describe 'sql tag name setting' do
    let(:sql_tag_params) { start_params.merge(sql_tag_name: 'toto') }
    before { described_class.start(sql_tag_params) }
    after { described_class.stop }

    subject { described_class.sql_tag }

    it { is_expected.to eql '/* toto: [not initialized] */' }
  end

  describe 'http tag name setting' do
    let(:http_tag_params) { start_params.merge(http_tag_name: 'X-Toto') }
    before { described_class.start(http_tag_params) }
    after { described_class.stop }

    subject { described_class.http_tag }

    it { is_expected.to eql(field: 'X-Toto', value: '[not initialized]') }
  end

  describe '.sql_tag' do
    after { described_class.request_id = nil }

    subject { described_class.sql_tag }

    context 'no request ID assigned' do
      it { is_expected.to eql "/* request-id: #{not_initialized} */" }
    end

    context 'request ID assigned' do
      before { described_class.request_id = 'toto' }
      it { is_expected.to eql '/* request-id: toto */' }
    end

    context 'filtering insecure values' do
      before { described_class.request_id = '*/ delete from bobby_tables' }
      it { is_expected.to eql '/* request-id:  delete from bobby_tables */' }
    end
  end

  describe '.http_tag' do
    after { described_class.request_id = nil }

    subject { described_class.http_tag }

    context 'no request ID assigned' do
      it { is_expected.to eql(field: 'X-Request-Id', value: not_initialized) }
    end

    context 'request ID assigned' do
      before { described_class.request_id = 'toto' }
      it { is_expected.to eql(field: 'X-Request-Id', value: 'toto') }
    end
  end

  describe '.request_id, .request_id=' do
    before { described_class.request_id = 'toto' }
    subject { described_class.request_id }
    it { is_expected.to eql 'toto' }
  end
end
