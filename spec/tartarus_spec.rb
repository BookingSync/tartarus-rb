RSpec.describe Tartarus do
  describe ".registry" do
    subject(:regisry) { described_class.registry }

    it { is_expected.to be_a Tartarus::Registry }
  end

  describe "#register" do
    subject(:register) do
      described_class.new.register do |item|
        item.model = model
        item.queue = queue
        item.cron = cron
        item.archive_items_older_than = archive_items_older_than
        item.timestamp_field = timestamp_field
      end
    end

    let(:model) { "model" }
    let(:queue) { "default" }
    let(:cron) { "* * * * *" }
    let(:archive_items_older_than) { -> {} }
    let(:timestamp_field) { :created_at }
    let(:registry) { Tartarus.registry }

    context "when the registered item is valid" do
      it "add items to registry" do
        expect {
          register
        }.to change { registry.size }.from(0).to(1)

        expect(registry.find_by_model(model)).to be_a(Tartarus::ArchivableItem)
      end
    end

    context "when the registered item is not valid" do
      let(:cron) { nil }

      it { is_expected_block.to raise_error /invalid cron string/ }
    end
  end

  describe "#schedule" do
    subject(:schedule) { tartarus.schedule }

    let(:tartarus) { described_class.new }
    let(:register) do
      tartarus.register do |item|
        item.model = model
        item.queue = queue
        item.cron = cron
        item.archive_items_older_than = archive_items_older_than
        item.timestamp_field = timestamp_field
      end
    end

    let(:model) { "model" }
    let(:queue) { "default" }
    let(:cron) { "* * * * *" }
    let(:archive_items_older_than) { -> {} }
    let(:timestamp_field) { :created_at }
    let(:created_scheduled_job) { Sidekiq::Cron::Job.find("TARTARUS_model") }

    before do
      register
    end

    around do |example|
      Sidekiq.redis { |redis| puts redis.flushall }

      example.run

      Sidekiq.redis { |redis| puts redis.flushall }
    end

    it "adds registered items to Sidekiq Cron schedule" do
      expect {
        schedule
      }.to change { Sidekiq::Cron::Job.count }.by(1)

      expect(created_scheduled_job).to be_a Sidekiq::Cron::Job
    end
  end
end
