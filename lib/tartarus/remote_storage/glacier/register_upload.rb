class Tartarus
  module RemoteStorage
    class Glacier
      class RegisterUpload
        attr_reader :archive_registry_factory, :clock
        private     :archive_registry_factory, :clock

        def initialize(archive_registry_factory, clock: Time)
          @archive_registry_factory = archive_registry_factory
          @clock = clock
        end

        def register(glacier_response, archivable_model, tenant_id_field, tenant_id)
          archive_registry_factory.new.tap do |archive_registry|
            archive_registry.glacier_location = glacier_response.location
            archive_registry.glacier_checksum = glacier_response.checksum
            archive_registry.glacier_archive_id = glacier_response.archive_id
            archive_registry.archivable_model = archivable_model
            archive_registry.tenant_id_field = tenant_id_field
            archive_registry.tenant_id = tenant_id
            archive_registry.completed_at = clock.now
            archive_registry.save!
          end
        end
      end
    end
  end
end
