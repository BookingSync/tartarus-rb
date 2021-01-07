RSpec.describe Tartarus::ArchiveStrategy::DeleteAllUsingLimitInBatches do
  describe "#call" do
    subject(:call) { described_class.new(batch_size: batch_size).call(collection) }

    let(:batch_size) { 100 }
    let(:collection) do
      Class.new do
        def initialize
          @deleted = false
          @limit_num = nil
        end

        def deleted?
          @deleted
        end

        def limit_num
          @limit_num
        end

        def delete_all
          @deleted = true
          0
        end

        def limit(num)
          @limit_num = num
          self
        end
      end.new
    end

    it "calls :delete_all on each batch" do
      expect {
        call
      }.to change { collection.deleted? }.from(false).to(true)
      .and change { collection.limit_num }.from(nil).to(batch_size)
    end
  end
end
