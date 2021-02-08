RSpec.describe Tartarus::RemoteStorage::Null do
  describe ".store" do
    context "with keyword arguments" do
      subject(:store) { described_class.store(double, double, a: double, b: double) }

      it "does nothing" do
        expect {
          store
        }.not_to raise_error
      end
    end

    context "without keyword arguments" do
      subject(:store) { described_class.store(double, double) }

      it "does nothing" do
        expect {
          store
        }.not_to raise_error
      end
    end
  end
end
