RSpec.describe Tartarus::Repository do
  describe "#save" do
    subject(:save) { repository.save(archivable_item) }

    let(:repository) { described_class.new }

    context "when archivable item can be serialized to a valid job" do
      around do |example|
        Sidekiq.redis { |redis| puts redis.flushall }

        example.run

        Sidekiq.redis { |redis| puts redis.flushall }
      end

      context "when the job does not exist" do
        let(:archivable_item) do
          Tartarus::ArchivableItem.new.tap do |item|
            item.model = "Model"
            item.cron = "* * * * *"
          end
        end
        let(:created_job) { Sidekiq::Cron::Job.find("TARTARUS_Model") }
        let(:expected_hash) do
          {
            active_job: false,
            args: "[\"Model\"]",
            cron: "* * * * *",
            description: "[TARTARUS] Archiving Job for model: Model",
            klass: "Tartarus::Sidekiq::ScheduleArchivingModelJob",
            last_enqueue_time: nil,
            message: "{\"retry\":true,\"queue\":\"default\",\"class\":\"Tartarus::Sidekiq::ScheduleArchivingModelJob\",\"args\":[\"Model\"]}",
            name: "TARTARUS_Model",
            queue_name_delimiter: "",
            queue_name_prefix: "",
            status: "enabled",
          }
        end

        it "creates the job" do
          expect {
            save
          }.to change { Sidekiq::Cron::Job.count }.by(1)
          expect(created_job.to_hash).to eq(expected_hash)
        end
      end

      context "when the job already exists" do
        subject(:save_before) { repository.save(archivable_item_before) }

        let(:archivable_item_before) do
          Tartarus::ArchivableItem.new.tap do |item|
            item.model = "Model"
            item.cron = "1 * * * *"
          end
        end
        let(:archivable_item) do
          Tartarus::ArchivableItem.new.tap do |item|
            item.model = "Model"
            item.cron = "* * * * *"
          end
        end

        before do
          save_before
        end

        it "updates the job" do
          expect {
            save
          }.to avoid_changing { Sidekiq::Cron::Job.count }
          .and change { Sidekiq::Cron::Job.find("TARTARUS_Model").cron }.from("1 * * * *").to("* * * * *")
        end
      end
    end

    context "when archivable item cannot be serialized to a valid job" do
      let(:archivable_item) { Tartarus::ArchivableItem.new }

      it "raises error" do
        expect {
          save
        }.to raise_error "could not save job: 'cron' must be set"
      end
    end
  end
end
