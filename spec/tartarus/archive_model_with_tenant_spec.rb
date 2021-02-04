RSpec.describe Tartarus::ArchiveModelWithTenant do
  describe "#archive" do
    subject(:archive) { service.archive(model_name, tenant_id) }

    let(:service) { described_class.new(registry: registry, repository: repository) }
    let(:model_name) { "ModelName" }
    let(:tenant_id) { 11 }

    let(:registry) { Tartarus::Registry.new }
    let(:repository) do
      Class.new do
        attr_reader :model_name, :timestamp_field, :archive_items_older_than, :tenant_id_field, :tenant_id

        def initialize
          @model_name = nil
          @timestamp_field = nil
          @archive_items_older_than = nil
          @tenant_id_field = nil
          @tenant_id = nil
          @deleted = false
        end

        def items_older_than_for_tenant(model_name, timestamp_field, archive_items_older_than, tenant_id_field, tenant_id)
          @model_name = model_name
          @timestamp_field = timestamp_field
          @archive_items_older_than = archive_items_older_than
          @tenant_id_field = tenant_id_field
          @tenant_id = tenant_id
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
        item.tenant_id_field = :tenant_id
        item.remote_storage = remote_storage
      end
    end
    let(:remote_storage) do
      Class.new do
        attr_reader :collection, :model_name, :tenant_id, :tenant_id_field

        def store(collection, model_name, tenant_id:, tenant_id_field:)
          @collection = collection
          @model_name = model_name
          @tenant_id = tenant_id
          @tenant_id_field = tenant_id_field
        end
      end.new
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
      .and change { repository.tenant_id_field }.from(nil).to(:tenant_id)
      .and change { repository.tenant_id }.from(nil).to(11)
      .and change { repository.deleted? }.from(false).to(true)
    end

    it "stores records in a remote storage" do
      expect {
        archive
      }.to change { remote_storage.collection }.from(nil).to(repository)
      .and change { remote_storage.model_name }.from(nil).to(model_name)
      .and change { remote_storage.tenant_id }.from(nil).to(11)
      .and change { remote_storage.tenant_id_field }.from(nil).to(:tenant_id)
    end
  end
end
