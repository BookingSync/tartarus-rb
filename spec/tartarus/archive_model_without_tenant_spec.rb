RSpec.describe Tartarus::ArchiveModelWithoutTenant do
  describe "#archive" do
    subject(:archive) { service.archive(model_name) }

    let(:service) { described_class.new(registry: registry, repository: repository) }
    let(:model_name) { "ModelName" }

    let(:registry) { Tartarus::Registry.new }
    let(:repository) do
      Class.new do
        attr_reader :model_name, :timestamp_field, :archive_items_older_than

        def initialize
          @model_name = nil
          @timestamp_field = nil
          @archive_items_older_than = nil
          @deleted = false
        end

        def items_older_than(model_name, timestamp_field, archive_items_older_than)
          @model_name = model_name
          @timestamp_field = timestamp_field
          @archive_items_older_than = archive_items_older_than
          self
        end

        def delete_all
          @deleted = true
        end

        def deleted?
          @deleted
        end

        def primary_key
          "id"
        end

        def select(*)
          self
        end

        def find_in_batches
          yield self
        end

        def where(*)
          self
        end
      end.new
    end
    let(:archivable_item) do
      Tartarus::ArchivableItem.new.tap do |item|
        item.model = model_name
        item.timestamp_field = :created_at
        item.archive_items_older_than = -> { Date.today }
      end
    end

    before do
      registry.register(archivable_item)
    end

    it "fetches records to be archived and archives them" do
      expect {
        archive
      }.to change { repository.model_name }.from(nil).to(model_name)
      .and change { repository.timestamp_field }.from(nil).to(:created_at)
      .and change { repository.archive_items_older_than }.from(nil).to(Date.today)
      .and change { repository.deleted? }.from(false).to(true)
    end
  end
end
