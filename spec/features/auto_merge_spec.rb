require 'spec_helper'

describe Jerakia do
  let(:subject) { Jerakia.new(:config =>  "#{JERAKIA_ROOT}/test/fixtures/etc/jerakia/jerakia.yaml") }
  let(:answer) { subject.lookup(request) }
  let(:request) do
    Jerakia::Request.new(
      metadata: { env: 'dev' },
      key: "#{first}_#{second}",
      lookup_type: :cascade,
      merge: merge_type,
      namespace: ['auto']
    )
  end

  shared_examples_for "auto merging" do
    context 'with a high priority scalar' do
      let(:first) { 'scalar' }

      context 'with a low priority scalar' do
        let(:second) { 'scalar' }

        it 'should have the high priority scalar as a payload' do
          expect(answer.payload).to eq("foo")
        end
      end

      context 'with a low priority array' do
        let(:second) { 'array' }

        it 'should have the high priority scalar as a payload' do
          expect(answer.payload).to eq("foo")
        end
      end

      context 'with a low priority hash' do
        let(:second) { 'hash' }

        it 'should have the high priority scalar as a payload' do
          expect(answer.payload).to eq("foo")
        end
      end
    end

    context 'with a high priority array' do
      let(:first) { 'array' }

      context 'with a low priority scalar' do
        let(:second) { 'scalar' }

        it 'should have the high priority array as a payload' do
          expect(answer.payload).to eq(['foo', 'bar'])
        end
      end

      context 'with a low priority array' do
        let(:second) { 'array' }

        it 'should have the contents of both arrays combined as a payload' do
          expect(answer.payload).to eq(['foo','bar','baz','mux'])
        end
      end

      context 'with a low priority hash' do
        let(:second) { 'hash' }

        it 'should have the high priority array as a payload' do
          expect(answer.payload).to eq(['foo','bar'])
        end
      end
    end

    context 'with a high priority hash' do
      let(:first) { 'hash' }

      context 'with a low priority scalar' do
        let(:second) { 'scalar' }

        it 'should have the high priority hash as a payload' do
          expect(answer.payload).to eq({ 'foo' => 'bar', 'baz' => {'mux' => 'fin'} })
        end
      end

      context 'with a low priority array' do
        let(:second) { 'array' }

        it 'should have the high-priority hash as a payload' do
          expect(answer.payload).to eq({ 'foo' => 'bar', 'baz' => {'mux' => 'fin'} })
        end
      end
    end

    context 'with mixed types' do
      let(:request) do
        Jerakia::Request.new(
          metadata: { env: 'dev', hostname: 'example' },
          key: "mixed_messages",
          lookup_type: :cascade,
          merge: merge_type,
          namespace: ['auto']
        )
      end

      it 'should stop the cascade when a type mismatch occurs' do
        expect(answer.payload).to eq({'foo' => 'bar', 'baz' => [1,2]})
      end
    end
  end


  context 'cascade auto result lookup' do
    let(:merge_type) { :auto }

    it_behaves_like "auto merging"

    context "with a high priority hash and a low priority hash" do
      let(:first) { 'hash' }
      let(:second) { 'hash' }

      it 'should have the shallow-merged hashes as a payload' do
        expect(answer.payload).to eq({ 'foo' => 'bar', 'bar' => 'wink', 'baz' => {'mux' => 'fin'} })
      end
    end
  end

  context 'cascade deep_auto result lookup' do
    let(:merge_type) { :deep_auto }

    it_behaves_like "auto merging"

    context "with a high priority hash and a low priority hash" do
      let(:first) { 'hash' }
      let(:second) { 'hash' }

      it 'should have the deep-merged hashes as a payload' do
        expect(answer.payload).to eq({ 'foo' => 'bar', 'bar' => 'wink', 'baz' => {'mux' => 'fin', 'ick' => 'bick'} })
      end
    end
  end
end