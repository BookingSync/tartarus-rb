RSpec.describe "Glacier Upload", :freeze_time do
  describe "without tenant-related fields" do
    subject(:upload_to_glacier) { remote_storage.store(collection, "User") }

    let(:remote_storage) { Tartarus::RemoteStorage::Glacier.new(configuration) }
    let(:collection) { User.all }
    let(:configuration) do
      Tartarus::RemoteStorage::Glacier::Configuration.build(
        aws_key: aws_key,
        aws_secret: aws_secret,
        aws_region: aws_region,
        vault_name: vault_name,
        root_path: root_path,
        archive_registry_factory: archive_registry_factory,
      )
    end

    let(:aws_key) { ENV.fetch("AWS_KEY") }
    let(:aws_secret) { ENV.fetch("AWS_SECRET") }
    let(:aws_region) { ENV.fetch("AWS_REGION") }
    let(:vault_name) { ENV.fetch("VAULT_NAME") }
    let(:root_path) { "#{$LOAD_PATH.first}" }
    let(:archive_registry_factory) { ArchiveRegistry }
    let(:csv_headers) { "id;created_at;partition_name" }
    let(:csv_body_part_1) { "#{User.first.id};2020-01-01 11:00:00;Partition_1" }
    let(:csv_body_part_2) { "#{User.last.id};2020-01-01 11:00:00;Partition_1" }
    let(:created_archive_registry) { ArchiveRegistry.last }

    before do
      Partition.create!(name: "Partition_1")
      2.times { User.create!(created_at: Time.new(2020, 1, 1, 12, 0, 0), partition_name: "Partition_1") }
    end

    after do
      User.delete_all
      Partition.delete_all
      ArchiveRegistry.delete_all
    end

    context "on success" do
      around do |example|
        VCR.use_cassette("Glacier_Upload_without_tenant_success") do
          example.run
        end
      end

      it "uploads exported CSV file to Glacier" do
        upload_to_glacier

        assert_requested(:post, "https://glacier.#{aws_region}.amazonaws.com/-/vaults/#{vault_name}/archives") do |req|
          req.body.include?(csv_headers) && req.body.include?(csv_body_part_1) && req.body.include?(csv_body_part_2)
        end
      end

      it "creates ArchiveRegistry record with all the important attributes" do
        expect {
          upload_to_glacier
        }.to change { ArchiveRegistry.count }.by(1)

        expect(created_archive_registry.attributes.except("id", "created_at", "updated_at")).to eq(
          "archivable_model" => "User",
          "completed_at" => Time.now,
          "glacier_archive_id" => "C4hLRuh_fz0gXPkuEggmiju7DwJLYYNIGvbh-I82vZuZReEa0w6j5-bntK-v4k8GS10oYmzCN5KmpvTGEB-cj_lxyhvSZQsDfN9LuA718bZLw0-rnc6-qT_yzDl03nFq4_87DGWDyg",
          "glacier_checksum" => "1231bdc7c570d7e7877105b2804824b4a3a87cd87f562720c06572d5ba7a95ae",
          "glacier_location" => "/441911171826/vaults/test-tartarus/archives/C4hLRuh_fz0gXPkuEggmiju7DwJLYYNIGvbh-I82vZuZReEa0w6j5-bntK-v4k8GS10oYmzCN5KmpvTGEB-cj_lxyhvSZQsDfN9LuA718bZLw0-rnc6-qT_yzDl03nFq4_87DGWDyg",
          "tenant_id" => nil,
          "tenant_id_field" => nil
        )
      end

      it "removes export file after it's done" do
        expect_any_instance_of(Tartarus::RemoteStorage::Glacier::File).to receive(:delete_from_local_storage).and_call_original

        upload_to_glacier
      end
    end

    context "on failure" do
      context "when file has been already created" do
        before do
          allow_any_instance_of(Tartarus::RemoteStorage::Glacier::Client).to receive(:upload_archive) { raise "surprise" }
        end

        it "removes export file" do
          expect_any_instance_of(Tartarus::RemoteStorage::Glacier::File).to receive(:delete_from_local_storage).and_call_original

          expect {
            upload_to_glacier
          }.to raise_error /surprise/
        end
      end

      context "when file has not been created yet" do
        before do
          allow_any_instance_of(Tartarus::RemoteStorage::Glacier::CsvExport).to receive(:export) { raise "surprise" }
        end

        it "does not try to remove any file" do
          expect_any_instance_of(Tartarus::RemoteStorage::Glacier::File).not_to receive(:delete_from_local_storage)

          expect {
            upload_to_glacier
          }.to raise_error /surprise/
        end
      end
    end
  end

  describe "with tenant-related fields" do
    subject(:upload_to_glacier) do
      remote_storage.store(collection, "User", tenant_id: "Partition_1", tenant_id_field: "partition_name")
    end

    let(:remote_storage) { Tartarus::RemoteStorage::Glacier.new(configuration) }
    let(:collection) { User.all }
    let(:configuration) do
      Tartarus::RemoteStorage::Glacier::Configuration.build(
        aws_key: aws_key,
        aws_secret: aws_secret,
        aws_region: aws_region,
        vault_name: vault_name,
        root_path: root_path,
        archive_registry_factory: archive_registry_factory,
      )
    end

    let(:aws_key) { ENV.fetch("AWS_KEY") }
    let(:aws_secret) { ENV.fetch("AWS_SECRET") }
    let(:aws_region) { ENV.fetch("AWS_REGION") }
    let(:vault_name) { ENV.fetch("VAULT_NAME") }
    let(:root_path) { "#{$LOAD_PATH.first}" }
    let(:archive_registry_factory) { ArchiveRegistry }
    let(:csv_headers) { "id;created_at;partition_name" }
    let(:csv_body_part_1) { "#{User.first.id};2020-01-01 11:00:00;Partition_1" }
    let(:csv_body_part_2) { "#{User.last.id};2020-01-01 11:00:00;Partition_1" }
    let(:created_archive_registry) { ArchiveRegistry.last }

    before do
      Partition.create!(name: "Partition_1")
      2.times { User.create!(created_at: Time.new(2020, 1, 1, 12, 0, 0), partition_name: "Partition_1") }
    end

    after do
      User.delete_all
      Partition.delete_all
      ArchiveRegistry.delete_all
    end

    context "on success" do
      around do |example|
        VCR.use_cassette("Glacier_Upload_with_tenant_success") do
          example.run
        end
      end

      it "uploads exported CSV file to Glacier" do
        upload_to_glacier

        assert_requested(:post, "https://glacier.#{aws_region}.amazonaws.com/-/vaults/#{vault_name}/archives") do |req|
          req.body.include?(csv_headers) && req.body.include?(csv_body_part_1) && req.body.include?(csv_body_part_2)
        end
      end

      it "creates ArchiveRegistry record with all the important attributes" do
        expect {
          upload_to_glacier
        }.to change { ArchiveRegistry.count }.by(1)

        expect(created_archive_registry.attributes.except("id", "created_at", "updated_at")).to eq(
          "archivable_model" => "User",
          "completed_at" => Time.now,
          "glacier_archive_id" => "7OPcmpwLr2xf3e5mLv6gnXhiZHUBvCjW2HNG0TGOdaxRRBjVV9P9O-WKNIJjX3nGROTxvV5sq1CcgmgZmoGnL3ClY1Xwo-0YMaxlW5BxuMLxYIPtJJmZMDUXYVG9cREcySvpkXGvWQ",
          "glacier_checksum" => "33be097eb49447dd7c61b8ddc6ba092f0b68a440f18fbe7947fa8a32c7bbc772",
          "glacier_location" => "/441911171826/vaults/test-tartarus/archives/7OPcmpwLr2xf3e5mLv6gnXhiZHUBvCjW2HNG0TGOdaxRRBjVV9P9O-WKNIJjX3nGROTxvV5sq1CcgmgZmoGnL3ClY1Xwo-0YMaxlW5BxuMLxYIPtJJmZMDUXYVG9cREcySvpkXGvWQ",
          "tenant_id" => "Partition_1",
          "tenant_id_field" => "partition_name"
        )
      end

      it "removes export file after it's done" do
        expect_any_instance_of(Tartarus::RemoteStorage::Glacier::File).to receive(:delete_from_local_storage).and_call_original

        upload_to_glacier
      end
    end

    context "on failure" do
      context "when file has been already created" do
        before do
          allow_any_instance_of(Tartarus::RemoteStorage::Glacier::Client).to receive(:upload_archive) { raise "surprise" }
        end

        it "removes export file" do
          expect_any_instance_of(Tartarus::RemoteStorage::Glacier::File).to receive(:delete_from_local_storage).and_call_original

          expect {
            upload_to_glacier
          }.to raise_error /surprise/
        end
      end

      context "when file has not been created yet" do
        before do
          allow_any_instance_of(Tartarus::RemoteStorage::Glacier::CsvExport).to receive(:export) { raise "surprise" }
        end

        it "does not try to remove any file" do
          expect_any_instance_of(Tartarus::RemoteStorage::Glacier::File).not_to receive(:delete_from_local_storage)

          expect {
            upload_to_glacier
          }.to raise_error /surprise/
        end
      end
    end
  end
end
