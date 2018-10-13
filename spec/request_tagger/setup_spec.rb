# frozen_string_literal: true

RSpec.describe RequestTagger::Setup do
  let(:setup) { described_class.new }

  subject { setup }

  it { is_expected.to be_a described_class }

  describe '.start' do
    let(:ar_adapter) do
      double(class_exec: nil, define_method: nil, instance_method: nil)
    end
    let(:ar_connection) { double(class: ar_adapter) }

    subject { described_class.start(active_record_connection: ar_connection) }

    it { is_expected.to be true }
  end

  describe '.sql_tag' do
    subject { described_class.sql_tag }

    context 'no request ID assigned' do
      it { is_expected.to eql '/* request-id: [not initialized] */' }
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

  describe '.request_id, .request_id=' do
    before { described_class.request_id = 'toto' }
    subject { described_class.request_id }
    it { is_expected.to eql 'toto' }
  end
end
