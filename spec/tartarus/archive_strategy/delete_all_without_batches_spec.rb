RSpec.describe Tartarus::ArchiveStrategy::DeleteAllWithoutBatches do
  describe "#call" do
    subject(:call) { described_class.new.call(collection) }

    let(:collection) do
      Class.new do
        def initialize
          @deleted = false
        end

        def deleted?
          @deleted
        end

        def delete_all
          @deleted = true
        end
      end.new
    end

    it "calls :delete_all on collection" do
      expect {
        call
      }.to change { collection.deleted? }.from(false).to(true)
    end
  end
end
