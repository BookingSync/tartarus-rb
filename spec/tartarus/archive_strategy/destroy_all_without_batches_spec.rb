RSpec.describe Tartarus::ArchiveStrategy::DestroyAllWithoutBatches do
  describe "#call" do
    subject(:call) { described_class.new.call(collection) }

    let(:collection) do
      Class.new do
        def initialize
          @destroyed = false
        end

        def destroyed?
          @destroyed
        end

        def destroy_all
          @destroyed = true
        end
      end.new
    end

    it "calls :destroy_all on collection in batches" do
      expect {
        call
      }.to change { collection.destroyed? }.from(false).to(true)
    end
  end
end
