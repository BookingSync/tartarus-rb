RSpec.describe Tartarus::ArchivableItem::SidekiqCronJobSerializer do
  describe "#serialize" do
    subject(:serialize) { serializer.serialize(item) }

    let(:serializer) { described_class.new }
    let(:item) { double(model: "ModelName", cron: "* * * * *", active_job: false, queue: "default", name: "my_name") }
    let(:expected_hash) do
      {
        name: "TARTARUS_my_name",
        description: "[TARTARUS] Archiving Job for model: ModelName",
        cron: "* * * * *",
        class: Tartarus::Sidekiq::ScheduleArchivingModelJob,
        args: ["my_name"],
        queue: "default",
        active_job: false
      }
    end

    it { is_expected.to eq expected_hash }
  end
end
