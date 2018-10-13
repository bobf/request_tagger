# frozen_string_literal: true

RSpec.describe RequestTagger do
  it 'has a version number' do
    expect(RequestTagger::VERSION).not_to be nil
  end

  before(:each) do
    # If we call `RequestTagger.stop` instead of hacking the state like this
    # then we get leftover doubles from previous tests and RSpec gets
    # (justifiably) upset.
    RequestTagger::Setup.instance_variable_set(:@initialized, false)
  end

  let(:ar_adapter) do
    double(class_exec: nil, define_method: nil, instance_method: nil)
  end

  let(:ar_connection) { double(class: ar_adapter) }

  describe 'repeated calls to .start' do
    subject do
      proc do
        described_class.start(active_record_connection: ar_connection)
        described_class.start(active_record_connection: ar_connection)
      end
    end

    it { is_expected.to raise_error(RequestTagger::AlreadyStartedError) }
  end
end
