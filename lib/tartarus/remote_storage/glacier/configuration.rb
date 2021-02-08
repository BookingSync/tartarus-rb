class Tartarus
  module RemoteStorage
    class Glacier
      class Configuration
        DEFAULT_ACCOUNT_ID = "-"
        private_constant :DEFAULT_ACCOUNT_ID

        REQUIRED_ATTRIBUTES_NAMES = %i(aws_key aws_secret aws_region account_id vault_name root_path
          archive_registry_factory).freeze
        attr_accessor *REQUIRED_ATTRIBUTES_NAMES

        def self.build(aws_key:, aws_secret:, aws_region:, account_id: DEFAULT_ACCOUNT_ID, vault_name:, root_path:, archive_registry_factory:)
          new.tap do |config|
            config.aws_key = aws_key
            config.aws_secret = aws_secret
            config.aws_region = aws_region
            config.account_id = account_id
            config.vault_name = vault_name
            config.root_path = root_path
            config.archive_registry_factory = archive_registry_factory
            config.validate!
          end
        end

        def validate!
          validate_presence
        end

        def storage_directory
          "#{root_path}/tmp/tartarus/#{archive_registry_factory}"
        end

        private

        def validate_presence
          REQUIRED_ATTRIBUTES_NAMES.each do |attribute|
            raise ":#{attribute} must be present" if public_send(attribute).nil?
          end
        end
      end
    end
  end
end
