RSpec.describe Tartarus::ArchiveStrategy do
  describe "#for" do
    subject(:for) { described_class.new.for(strategy_name, batch_size: 100) }

    context "when strategy_name is 'delete_all'" do
      let(:strategy_name) { :delete_all }

      it { is_expected.to be_a Tartarus::ArchiveStrategy::DeleteAll }
    end

    context "when strategy_name is 'delete_all_without_batches'" do
      let(:strategy_name) { "delete_all_without_batches" }

      it { is_expected.to be_a Tartarus::ArchiveStrategy::DeleteAllWithoutBatches }
    end

    context "when strategy_name is 'destroy_all'" do
      let(:strategy_name) { "destroy_all" }

      it { is_expected.to be_a Tartarus::ArchiveStrategy::DestroyAll }
    end

    context "when strategy_name is 'destroy_all_without_batches'" do
      let(:strategy_name) { :destroy_all_without_batches }

      it { is_expected.to be_a Tartarus::ArchiveStrategy::DestroyAllWithoutBatches }
    end

    context "when strategy_name is 'delete_all_using_limit_in_batches'" do
      let(:strategy_name) { :delete_all_using_limit_in_batches }

      it { is_expected.to be_a Tartarus::ArchiveStrategy::DeleteAllUsingLimitInBatches }
    end

    context "when strategy_name is something else" do
      let(:strategy_name) { "whatever" }

      it { is_expected_block.to raise_error "unknown strategy: whatever" }
    end
  end
end
