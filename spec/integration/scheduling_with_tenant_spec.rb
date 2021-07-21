RSpec.describe "Integration Test: Scheduling Archiving With Tenant" do
  subject(:schedule) do
    Tartarus::ScheduleArchivingModel.new(registry: registry).schedule("User")
  end

  let(:registry) { Tartarus::Registry.new }
  let(:archivable_item) do
    Tartarus::ArchivableItem.new.tap do |item|
      item.model = User
      item.timestamp_field = :created_at
      item.archive_items_older_than = -> { Date.today }
      item.tenants_range = -> { Partition }
      item.tenant_id_field = :partition_name
      item.tenant_value_source = :name
      item.queue = "default"
    end
  end

  before do
    registry.register(archivable_item)

    Partition.create!(name: "name_1")
    Partition.create!(name: "name_2")
  end

  after do
    Partition.delete_all
  end

  it "schedules jobs for each tenant" do
    expect(Tartarus::Sidekiq::ArchiveModelWithTenantJob).not_to have_enqueued_sidekiq_job("User", "name_1")
    expect(Tartarus::Sidekiq::ArchiveModelWithTenantJob).not_to have_enqueued_sidekiq_job("User", "name_2")

    schedule

    expect(Tartarus::Sidekiq::ArchiveModelWithTenantJob).to have_enqueued_sidekiq_job("User", "name_1")
    expect(Tartarus::Sidekiq::ArchiveModelWithTenantJob).to have_enqueued_sidekiq_job("User", "name_2")
  end
end
