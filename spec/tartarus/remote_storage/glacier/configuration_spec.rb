RSpec.describe Tartarus::RemoteStorage::Glacier::Configuration do
  describe ".build" do
    subject(:build) do
      described_class.build(
        aws_key: aws_key,
        aws_secret: aws_secret,
        aws_region: aws_region,
        vault_name: vault_name,
        root_path: root_path,
        account_id: account_id,
        archive_registry_factory: archive_registry_factory,
       )
    end

    context "when all required attributes are present" do
      let(:aws_key) { "aws_key" }
      let(:aws_secret) { "aws_secret" }
      let(:aws_region) { "aws_region" }
      let(:vault_name) { "vault_name" }
      let(:root_path) { "root_path" }
      let(:account_id) { "account_id" }
      let(:archive_registry_factory) { "archive_registry_factory" }

      it "returns config object with the set up attributes" do
        expect(build).to be_a Tartarus::RemoteStorage::Glacier::Configuration
        expect(build.aws_key).to eq aws_key
        expect(build.aws_secret).to eq aws_secret
        expect(build.aws_region).to eq aws_region
        expect(build.vault_name).to eq vault_name
        expect(build.root_path).to eq root_path
        expect(build.archive_registry_factory).to eq archive_registry_factory
        expect(build.account_id).to eq "account_id"
      end

      context "when :account_id is not passed" do
        subject(:build) do
          Tartarus::RemoteStorage::Glacier::Configuration.build(
            aws_key: aws_key,
            aws_secret: aws_secret,
            aws_region: aws_region,
            vault_name: vault_name,
            root_path: root_path,
            archive_registry_factory: archive_registry_factory,
           )
        end

        it "is ok, it will return default account ID in such case" do
          expect(build.account_id).to eq "-"
        end
      end
    end

    context "when not all required attributes are present" do
      let(:aws_key) { "aws_key" }
      let(:aws_secret) { "aws_secret" }
      let(:aws_region) { "aws_region" }
      let(:vault_name) { "vault_name" }
      let(:root_path) { "root_path" }
      let(:account_id) { "account_id" }
      let(:archive_registry_factory) { "archive_registry_factory" }

      context "when aws_key is not present" do
        let(:aws_key) { nil }

        it { is_expected_block.to raise_error ":aws_key must be present"  }
      end

      context "when aws_secret is not present" do
        let(:aws_secret) { nil }

        it { is_expected_block.to raise_error ":aws_secret must be present"  }
      end

      context "when aws_secret is not present" do
        let(:aws_region) { nil }

        it { is_expected_block.to raise_error ":aws_region must be present"  }
      end

      context "when vault_name is not present" do
        let(:vault_name) { nil }

        it { is_expected_block.to raise_error ":vault_name must be present"  }
      end

      context "when root_path is not present" do
        let(:root_path) { nil }

        it { is_expected_block.to raise_error ":root_path must be present"  }
      end

      context "when archive_registry_factory is not present" do
        let(:archive_registry_factory) { nil }

        it { is_expected_block.to raise_error ":archive_registry_factory must be present"  }
      end
    end
  end

  describe "#storage_directory" do
    subject(:storage_directory) do
      described_class.build(
        aws_key: aws_key,
        aws_secret: aws_secret,
        aws_region: aws_region,
        vault_name: vault_name,
        root_path: root_path,
        account_id: account_id,
        archive_registry_factory: archive_registry_factory,
      ).storage_directory
    end

    let(:aws_key) { "aws_key" }
    let(:aws_secret) { "aws_secret" }
    let(:aws_region) { "aws_region" }
    let(:vault_name) { "vault_name" }
    let(:root_path) { "root_path" }
    let(:account_id) { "account_id" }
    let(:archive_registry_factory) { "archive_registry_factory" }


    it { is_expected.to eq "#{root_path}/tmp/tartarus/#{archive_registry_factory}" }
  end
end
