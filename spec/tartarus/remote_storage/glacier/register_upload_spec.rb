RSpec.describe Tartarus::RemoteStorage::Glacier::RegisterUpload do
  describe "#register" do
    subject(:register) { register_upload.register(glacier_response, archivable_model, tenant_id_field, tenant_id) }

    let(:register_upload) { described_class.new(archive_registry_factory, clock: clock) }
    let(:archive_registry_factory) do
      Class.new do
        attr_accessor :glacier_location, :glacier_checksum, :glacier_archive_id, :archivable_model,
          :tenant_id, :tenant_id_field, :tenant_id, :completed_at

        def save!
          @saved = true
        end

        def saved?
          @saved = true
        end
      end
    end
    let(:clock) { double(now: now) }
    let(:now) { Time.now }
    let(:glacier_response) { double(location: "location", checksum: "checksum", archive_id: "archive_id") }
    let(:archivable_model) { "archivable_model" }
    let(:tenant_id_field) { "tenant_id_field" }
    let(:tenant_id) { "tenant_id" }

    it "persists a reigstry record with filled attributes" do
      expect(register).to be_saved
      expect(register.glacier_location).to eq "location"
      expect(register.glacier_checksum).to eq "checksum"
      expect(register.glacier_archive_id).to eq "archive_id"
      expect(register.archivable_model).to eq "archivable_model"
      expect(register.tenant_id_field).to eq "tenant_id_field"
      expect(register.tenant_id).to eq "tenant_id"
      expect(register.completed_at).to eq now
    end
  end
end
