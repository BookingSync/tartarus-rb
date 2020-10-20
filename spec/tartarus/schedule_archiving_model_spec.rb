RSpec.describe Tartarus::ScheduleArchivingModel do
  describe "#schedule" do
    subject(:schedule) { described_class.new(registry: registry).schedule(model_name) }

    let(:registry) { Tartarus::Registry.new }
    let(:model_name) { "ModelName" }

    context "when archivable item for a given model name is found" do
      let(:archivable_item) do
        Tartarus::ArchivableItem.new.tap do |item|
          item.model = model_name
          item.tenants_range = tenants_range
          item.tenant_id_field = tenant_id_field
          item.queue = queue
          item.tenant_value_source = :uuid
        end
      end
      let(:queue) { "critical" }

      before do
        registry.register(archivable_item)
      end

      context "when it's scoped by tenant" do
        let(:tenant_id_field) { :account_id }

        context "when it's scoped by ActiveRecord-like collection" do
          let(:tenants_range) { -> { fake_active_record_like_collection } }
          let(:fake_active_record_like_collection) do
            Class.new do
              attr_reader :elements

              def initialize(elements)
                @elements = elements
              end

              def find_each
                elements.each { |element| yield element }
              end
            end.new(elements)
          end
          let(:elements) { [double(uuid: 1), double(uuid: 2)] }

          it "enqueues Tartarus::Sidekiq::ArchiveModelWithTenantJob" do
            expect(Tartarus::Sidekiq::ArchiveModelWithTenantJob).not_to have_enqueued_sidekiq_job(model_name, 1)
            expect(Tartarus::Sidekiq::ArchiveModelWithTenantJob).not_to have_enqueued_sidekiq_job(model_name, 2)

            schedule

            expect(Tartarus::Sidekiq::ArchiveModelWithTenantJob).to have_enqueued_sidekiq_job(model_name, 1)
            expect(Tartarus::Sidekiq::ArchiveModelWithTenantJob).to have_enqueued_sidekiq_job(model_name, 2)
          end

          it "enqueues job to the queue specified in the config" do
            expect(Tartarus::Sidekiq::ArchiveModelWithTenantJob).to receive(:set)
              .with(queue: "critical").exactly(2).and_call_original

            schedule
          end
        end

        context "when it's not scoped by ActiveRecord-like collection" do
          let(:tenants_range) { -> { [1, 2] } }

          it "enqueues Tartarus::Sidekiq::ArchiveModelWithTenantJob" do
            expect(Tartarus::Sidekiq::ArchiveModelWithTenantJob).not_to have_enqueued_sidekiq_job(model_name, 1)
            expect(Tartarus::Sidekiq::ArchiveModelWithTenantJob).not_to have_enqueued_sidekiq_job(model_name, 2)

            schedule

            expect(Tartarus::Sidekiq::ArchiveModelWithTenantJob).to have_enqueued_sidekiq_job(model_name, 1)
            expect(Tartarus::Sidekiq::ArchiveModelWithTenantJob).to have_enqueued_sidekiq_job(model_name, 2)
          end

          it "enqueues job to the queue specified in the config" do
            expect(Tartarus::Sidekiq::ArchiveModelWithTenantJob).to receive(:set)
              .with(queue: "critical").exactly(2).and_call_original

            schedule
          end
        end
      end

      context "when it's not scoped by tenant" do
        let(:tenants_range) { -> { [] } }
        let(:tenant_id_field) { nil }

        it "enqueues Tartarus::Sidekiq::ArchiveModelWithoutTenantJob" do
          expect(Tartarus::Sidekiq::ArchiveModelWithoutTenantJob).not_to have_enqueued_sidekiq_job(model_name)

          schedule

          expect(Tartarus::Sidekiq::ArchiveModelWithoutTenantJob).to have_enqueued_sidekiq_job(model_name)
        end

        it "enqueues job to the queue specified in the config" do
          expect(Tartarus::Sidekiq::ArchiveModelWithoutTenantJob).to receive(:set)
            .with(queue: "critical").and_call_original

          schedule
        end
      end
    end

    context "when archivable item for a given model name is not found" do
      it { is_expected_block.to raise_error "ModelName not found in registry" }
    end
  end
end
