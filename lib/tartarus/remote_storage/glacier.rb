class Tartarus
  module RemoteStorage
    class Glacier
      attr_reader :configuration, :clock
      private     :configuration, :clock

      def initialize(configuration, clock: Time)
        @configuration = configuration
        @clock = clock
      end

      def store(collection, archivable_model, tenant_id: nil, tenant_id_field: nil)
        path_to_file = path_to_file_for(archivable_model, tenant_id_field, tenant_id)
        export_to_csv(collection, path_to_file)
        glacier_file = Tartarus::RemoteStorage::Glacier::File.new(::File.new(path_to_file))
        glacier_response = upload(glacier_file)
        register_upload(glacier_response, archivable_model, tenant_id_field, tenant_id)
      ensure
        glacier_file.delete_from_local_storage if glacier_file
      end

      private

      def upload(file)
        client.upload_archive(configuration.vault_name, file)
      end

      def client
        @client ||= begin
          Tartarus::RemoteStorage::Glacier::Client.new(
            key: configuration.aws_key,
            secret: configuration.aws_secret,
            region: configuration.aws_region,
            account_id: configuration.account_id,
          )
        end
      end

      def export_to_csv(collection, path_to_file)
        Tartarus::RemoteStorage::Glacier::CsvExport
          .new(configuration.storage_directory)
          .export(collection, path_to_file)
      end


      def register_upload(glacier_response, archivable_model, tenant_id_field, tenant_id)
        Tartarus::RemoteStorage::Glacier::RegisterUpload.new(configuration.archive_registry_factory).register(
          glacier_response,
          archivable_model,
          tenant_id_field,
          tenant_id
        )
      end

      def path_to_file_for(archivable_model, tenant_id_field, tenant_id)
        "#{configuration.storage_directory}/#{archivable_model}_#{tenant_id_field}_#{tenant_id}_#{clock.now.to_i}.csv"
      end
    end
  end
end
