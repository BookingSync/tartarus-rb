RSpec.describe Tartarus::Sidekiq::ScheduleArchivingModelJob do
  describe "#perform" do
    subject(:perform) { described_class.new.perform(model_name) }

    let(:model_name) { "model_name" }

    let(:registry) { Tartarus.registry }
    let(:tartarus) { Tartarus.new }

    around do |example|
      tartarus.register do |item|
        item.model = model_name
        item.cron = "* * * * *"
        item.timestamp_field = :created_at
        item.archive_items_older_than = -> { Date.today }
        item.queue = "default"
      end

      example.run

      registry.reset
    end


    it "calls Tartarus::ScheduleArchivingModel with model name" do
      expect_any_instance_of(Tartarus::ScheduleArchivingModel).to receive(:schedule)
        .with(model_name).and_call_original
      expect(Tartarus::Sidekiq::ArchiveModelWithoutTenantJob).not_to have_enqueued_sidekiq_job(model_name)

      perform

      expect(Tartarus::Sidekiq::ArchiveModelWithoutTenantJob).to have_enqueued_sidekiq_job(model_name)
    end
  end
end
