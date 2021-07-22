RSpec.describe "Integration Test: Scheduling Archiving Without Tenant" do
  subject(:schedule) do
    Tartarus::ScheduleArchivingModel.new(registry: registry).schedule("User")
  end

  let(:registry) { Tartarus::Registry.new }
  let(:archivable_item) do
    Tartarus::ArchivableItem.new.tap do |item|
      item.model = User
      item.timestamp_field = :created_at
      item.archive_items_older_than = -> { Date.today }
      item.queue = "default"
    end
  end

  before do
    registry.register(archivable_item)
  end

  it "schedules jobs for each tenant" do
    expect(Tartarus::Sidekiq::ArchiveModelWithoutTenantJob).not_to have_enqueued_sidekiq_job("User")

    schedule

    expect(Tartarus::Sidekiq::ArchiveModelWithoutTenantJob).to have_enqueued_sidekiq_job("User")
  end
end
