# frozen_string_literal: true

RSpec.describe RequestTagger::ActiveRecordMagic do
  class DummyAdapter
    RETURN_VALUE = 'some return value'

    def exec_query(_sql)
      RETURN_VALUE
    end

    def execute(_sql)
      RETURN_VALUE
    end
  end

  before do
    allow(RequestTagger::Setup)
      .to receive(:sql_tag)
      .and_return(tag)
  end

  let(:ar_adapter) { DummyAdapter }
  let(:ar_connection) { ar_adapter.new }
  let(:active_record_magic) { described_class.new(ar_connection) }
  let(:tag) { '/* test-tag */' }
  let(:copied_method_name) { :"__request_tagger_original__#{method_name}__" }
  let(:sql) { 'select * from table' }
  let(:tagged_sql) { "#{tag} #{sql}" }

  subject { active_record_magic }

  it { is_expected.to be_a described_class }

  shared_examples 'a wrapped method' do
    before do
      active_record_magic.wrap
      expect(ar_connection)
        .to receive(copied_method_name)
        .with(tagged_sql)
        .and_call_original
    end

    after { active_record_magic.restore }

    subject { ar_connection.public_send(method_name, sql) }

    it { is_expected.to eql DummyAdapter::RETURN_VALUE }
  end

  shared_examples 'a restored method' do
    before do
      active_record_magic.wrap
      active_record_magic.restore
      expect(ar_connection)
        .to_not receive(copied_method_name)
    end

    subject { ar_connection.exec_query(sql) }

    it { is_expected.to eql DummyAdapter::RETURN_VALUE }
  end

  describe '#wrap, #restore' do
    context 'exec_query' do
      let(:method_name) { :exec_query }
      it_behaves_like 'a wrapped method'
      it_behaves_like 'a restored method'
    end

    context 'execute' do
      let(:method_name) { :execute }
      it_behaves_like 'a wrapped method'
      it_behaves_like 'a restored method'
    end
  end
end
