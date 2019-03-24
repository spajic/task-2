require 'spec_helper'

RSpec.describe 'Dummy' do
  subject { work }

  let(:result) { File.read('result.json') }

  context 'small file' do
    let!(:reference_result) { File.read('./spec/fixtures/reference_result.json') }

    before { prepare_file('./spec/fixtures/data.txt') }
    after { clean }

    it 'result stil the same' do
      subject
      expect(result).to eq reference_result
    end
  end

  context 'medium file work not slowly then before' do
    before { prepare_file('./spec/fixtures/data_medium-10k.txt') }
    after { clean }

    let!(:time) do
      Benchmark.realtime do
        subject
      end.round(4)
    end

    let(:not_slowly) { time < 0.12 }

    it { expect(not_slowly).to be true }
  end
end
