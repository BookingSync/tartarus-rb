RSpec.describe "Integration Test: Archiving Without Using In Batches From Rails 6" do
  subject(:archive) do
    Tartarus::ArchiveModelWithoutTenant.new(registry: registry).archive(UserWithoutInBatches)
  end

  let(:registry) { Tartarus::Registry.new }
  let(:archivable_item) do
    Tartarus::ArchivableItem.new.tap do |item|
      item.model = UserWithoutInBatches
      item.timestamp_field = :created_at
      item.archive_items_older_than = -> { Date.today }
      item.archive_with = archive_with
    end
  end
  let(:archive_with) { :destroy_all }

  before do
    registry.register(archivable_item)

    100.times { UserWithoutInBatches.create!(created_at: Time.new(2020, 1, 1, 12, 0, 0, 0), partition_name: "Partition_1") }
    50.times { UserWithoutInBatches.create!(created_at: Time.new(2020, 1, 1, 12, 0, 0, 0), partition_name: "Partition_2") }
    20.times { UserWithoutInBatches.create!(created_at: Time.new(2030, 1, 1, 12, 0, 0, 0), partition_name: "Partition_1") }
    20.times { UserWithoutInBatches.create!(created_at: Time.new(2030, 1, 1, 12, 0, 0, 0), partition_name: "Partition_2") }
  end

  around do |example|
    original_value = Thread.current["__TARTARUS__SUPPRESSED_IN_BATCHES"]
    Thread.current["__TARTARUS__SUPPRESSED_IN_BATCHES"] = true

    example.run

    Thread.current["__TARTARUS__SUPPRESSED_IN_BATCHES"] = original_value
  end

  after do
    UserWithoutInBatches.delete_all
  end

  describe "for delete_all" do
    let(:archive_with) { :delete_all }

    it "deletes Users without using in_batches" do
      expect {
        archive
      }.to change { UserWithoutInBatches.count }.from(190).to(40)
    end
  end

  describe "for destroy_all" do
    let(:archive_with) { :destroy_all }

    it "deletes Users without using in_batches" do
      expect {
        archive
      }.to change { UserWithoutInBatches.count }.from(190).to(40)
    end
  end
end
