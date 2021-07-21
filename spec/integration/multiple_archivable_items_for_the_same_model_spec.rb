RSpec.describe "Integration Test: Archiving Without Using In Batches From Rails 6" do
  subject(:archive) do
    Tartarus::ArchiveModelWithoutTenant.new(registry: registry).archive("critical_users")
  end

  let(:registry) { Tartarus::Registry.new }
  let(:archivable_item) do
    Tartarus::ArchivableItem.new.tap do |item|
      item.model = User
      item.timestamp_field = :created_at
      item.archive_items_older_than = -> { Time.new(2021, 1, 1, 12, 0, 0, 0) }
      item.archive_with = archive_with
      item.name = "critical_users"
    end
  end

  let(:archivable_item_1) do
    Tartarus::ArchivableItem.new.tap do |item|
      item.model = User
      item.timestamp_field = :created_at
      item.archive_items_older_than = -> { Time.new(2025, 1, 1, 12, 0, 0, 0) }
      item.archive_with = archive_with
      item.name = "low_priority_users"
    end
  end
  let(:archive_with) { :destroy_all }

  before do
    registry.register(archivable_item)
    registry.register(archivable_item_1)

    100.times { User.create!(created_at: Time.new(2020, 1, 1, 12, 0, 0, 0), partition_name: "Partition_1") }
    50.times { User.create!(created_at: Time.new(2022, 1, 1, 12, 0, 0, 0), partition_name: "Partition_1") }
    20.times { User.create!(created_at: Time.new(2024, 1, 1, 12, 0, 0, 0), partition_name: "Partition_1") }
    10.times { User.create!(created_at: Time.new(2036, 1, 1, 12, 0, 0, 0), partition_name: "Partition_1") }
  end

  after do
    User.delete_all
  end

  describe "for delete_all" do
    let(:archive_with) { :delete_all }

    it "deletes Users only with partition specified in critical_users strategy" do
      expect {
        archive
      }.to change { User.count }.from(180).to(80)
    end
  end

  describe "for destroy_all" do
    let(:archive_with) { :destroy_all }

    it "deletes Users only with partition specified in critical_users strategy" do
      expect {
        archive
      }.to change { User.count }.from(180).to(80)
    end
  end
end
