require 'spec_helper'

describe Jerakia do
  let(:subject) { Jerakia.new(:config =>  "#{JERAKIA_ROOT}/test/fixtures/etc/jerakia/jerakia.yaml") }
  let(:answer) { subject.lookup(request) }
  let(:lookup_type) { :first }
  let(:merge_type) { false }
  let(:request) do
    Jerakia::Request.new(
      key: key,
      namespace: [ 'interpolate' ],
      metadata: { "env" => "dev" },
      policy: 'interpolate',
      lookup_type: lookup_type,
      merge: merge_type
    )
  end

  shared_examples_for "a successful lookup" do
    it 'returns a response' do
      expect(answer).to be_a(Jerakia::Answer)
    end

    it 'is in a found state' do
      expect(answer.found?).to eq(true)
    end
  end

  describe 'Interpolate values' do
    context "when value contains scope substitution" do
      let(:key) { 'sub_value' }

      it_behaves_like "a successful lookup"

      it 'returns the answer' do
        expect(answer.payload).to eq('Environment is dev')
      end
    end

    context "when value contains literal escaped %{} string" do
      let(:key) { 'sub_escape_value' }

      it_behaves_like "a successful lookup"

      it 'treats %{} as a literal percent sign' do
        expect(answer.payload).to eq('%{looks fine to me}')
      end
    end

    context "when value contains literal escaped ${} string" do
      let(:key) { 'lookup_escape_value' }

      it_behaves_like "a successful lookup"

      it 'treats ${} as a literal dollar sign' do
        expect(answer.payload).to eq('${looks fine to me}')
      end
    end

    context "when value contains lookup substitution" do
      context "when interpolating a scalar value" do
        let(:key) { 'lookup_value' }

        it_behaves_like "a successful lookup"

        it 'returns the answer' do
          expect(answer.payload).to eq('Hello, World')
        end
      end

      context "when interpolating a collection" do
        let(:key) { 'lookup_value_collection' }

        it_behaves_like "a successful lookup"

        it 'does the best it can' do
          expect(answer.payload).to eq('Hello, [1, 2, 3]')
        end
      end

      context "when interpolating a namespaced key" do
        let(:key) { 'lookup_value_namespaced' }

        it_behaves_like "a successful lookup"

        it 'looks up the value in the indicated namespace' do
          expect(answer.payload).to eq('Hello, valid_string')
        end
      end

      context "when interpolating a layered key with cascading" do
        let(:lookup_type) { :cascade }
        let(:merge_type) { :array }
        let(:key) { 'lookup_value_layered' }

        it_behaves_like "a successful lookup"

        it "doesn't use cascading on the recursive lookup" do
          expect(answer.payload).to eq(['Hello, just_one_string'])
        end
      end

      context "when interpolating a self-referential key" do
        let(:key) { 'lookup_value_self_reference' }

        it 'raises a Jerakia::Error' do
          expect { answer.payload }.to raise_error(Jerakia::Error)
        end
      end

      context "when interpolating a namespaced self-referential key" do
        let(:key) { 'lookup_namespaced_self_reference' }

        it 'raises a Jerakia::Error' do
          expect { answer.payload }.to raise_error(Jerakia::Error)
        end
      end

      context "when interpolating cyclical references" do
        let(:key) { 'lookup_value_cyclical_reference' }

        it 'raises a Jerakia::Error' do
          expect { answer.payload }.to raise_error(Jerakia::Error)
        end
      end

      context "when interpolating namespaced cyclical references" do
        let(:key) { 'lookup_namespaced_cyclical_reference' }

        it 'raises a Jerakia::Error' do
          expect { answer.payload }.to raise_error(Jerakia::Error)
        end
      end

      context "when interpolating similar keys from different namespaces" do
        let(:key) { 'lookup_namespaced_similar_reference' }

        it_behaves_like "a successful lookup"

        it 'returns the correct final answer' do
          expect(answer.payload).to eq('L1, L2, L3, L4')
        end
      end

      context "when interpolating a diggable key" do
        let(:key) { 'lookup_diggable' }

        it_behaves_like "a successful lookup"

        it 'returns the correct final answer' do
          expect(answer.payload).to eq('Hello, Governor')
        end
      end

      context "when interpolating a diggable key with escaped dots in it" do
        let(:key) { 'lookup_tricky_dig' }

        it_behaves_like "a successful lookup"

        it 'returns the expected answer' do
          expect(answer.payload).to eq("He was born on 1888-09-26")
        end
      end
    end
  end
end
