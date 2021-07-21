RSpec.describe Tartarus::Registry do
  describe "#find_by_name" do
    subject(:find_by_name) { registry.find_by_name(name) }

    let(:registry) { described_class.new }
    let(:name_1) { "OtherModelName" }
    let(:item_1) { Tartarus::ArchivableItem.new.tap { |item| item.name = name_1 } }
    let(:name) { "ModelName" }
    let(:item) { Tartarus::ArchivableItem.new.tap { |item| item.name = name } }

    before do
      registry.register(item_1)
    end

    context "when there is an item for a given model" do
      before do
        registry.register(item)
      end

      it { is_expected.to eq item }
    end

    context "when there is no item for a given model" do
      it { is_expected_block.to raise_error "ModelName not found in registry" }
    end
  end

  describe "#reset" do
    subject(:reset) { registry.reset }

    let(:registry) { described_class.new }
    let(:item) { double }

    before do
      registry.register(item)
    end

    it "resets registry" do
      expect {
        reset
      }.to change { registry.size }.from(1).to(0)
    end
  end
end
