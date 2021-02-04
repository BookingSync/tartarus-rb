# frozen_string_literal: true

class Tartarus
  module RemoteStorage
    class Glacier
      class Client
        attr_reader :client, :account_id
        private     :client, :account_id

        def initialize(key:, secret:, region:, account_id:)
          @client = Aws::Glacier::Client.new(credentials: Aws::Credentials.new(key, secret), region: region)
          @account_id = account_id
        end

        def upload_archive(vault_name, file)
          client.upload_archive(
            account_id: account_id,
            archive_description: file.description,
            body: file.body,
            vault_name: vault_name
          )
        end
      end
    end
  end
end
