RSpec.describe "Integration Test: Archiving Using DeleteAll With Limit In Batches" do
  subject(:archive) do
    Tartarus::ArchiveModelWithTenant.new(registry: registry).archive("User", "Partition_1")
  end

  let(:registry) { Tartarus::Registry.new }
  let(:archivable_item) do
    Tartarus::ArchivableItem.new.tap do |item|
      item.model = User
      item.timestamp_field = :created_at
      item.archive_items_older_than = -> { Date.today }
      item.archive_with = archive_with
      item.tenants_range = -> { ["Partition_1", "Partition_2"] }
      item.tenant_id_field = :partition_name
      item.batch_size = 20
    end
  end

  before do
    registry.register(archivable_item)

    User.delete_all

    100.times { User.create!(created_at: Time.new(2020, 1, 1, 12, 0, 0, 0), partition_name: "Partition_1") }
    50.times { User.create!(created_at: Time.new(2020, 1, 1, 12, 0, 0, 0), partition_name: "Partition_2") }
    20.times { User.create!(created_at: Time.new(2030, 1, 1, 12, 0, 0, 0), partition_name: "Partition_1") }
    20.times { User.create!(created_at: Time.new(2030, 1, 1, 12, 0, 0, 0), partition_name: "Partition_2") }
  end

  after do
    User.delete_all
  end

  describe "for delete_all" do
    let(:archive_with) { :delete_all_using_limit_in_batches }

    it "deletes Users using in_batches" do
      expect {
        archive
      }.to change { User.count }.from(190).to(90)
    end
  end
end
