RSpec.describe "Archiving With Glacier Upload", :freeze_time do
  context "with tenant" do
    subject(:archive) do
      Tartarus::ArchiveModelWithTenant.new(registry: registry).archive("User", "Partition_1")
    end

    let(:registry) { Tartarus::Registry.new }
    let(:archivable_item) do
      Tartarus::ArchivableItem.new.tap do |item|
        item.model = User
        item.timestamp_field = :created_at
        item.archive_items_older_than = -> { Date.today }
        item.archive_with = :delete_all_using_limit_in_batches
        item.tenants_range = -> { ["Partition_1", "Partition_2"] }
        item.tenant_id_field = :partition_name
        item.batch_size = 20
        item.remote_storage = Tartarus::RemoteStorage::Glacier.new(glacier_configuration)
      end
    end
    let(:glacier_configuration) do
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
    let(:csv_body_part) { "#{User.minimum(:id) - 1};2020-01-01 12:00:00;Partition_1" } # first 100 records were deleted, so we need the last previous ID
    let(:created_archive_registry) { ArchiveRegistry.last }
    let(:expected_numbers_of_rows_in_csv_file) { 1 + 100 } # headers + deleted rows

    before do
      registry.register(archivable_item)

      User.delete_all

      100.times { User.create!(created_at: Time.new(2020, 1, 1, 12, 0, 0, 0), partition_name: "Partition_1") }
      50.times { User.create!(created_at: Time.new(2020, 1, 1, 12, 0, 0, 0), partition_name: "Partition_2") }
      20.times { User.create!(created_at: Time.new(2030, 1, 1, 12, 0, 0, 0), partition_name: "Partition_1") }
      20.times { User.create!(created_at: Time.new(2030, 1, 1, 12, 0, 0, 0), partition_name: "Partition_2") }
    end

    around do |example|
      VCR.use_cassette("Archiving_With_Glacier_Upload_with_tenant") do
        example.run
      end
    end

    after do
      User.delete_all
      ArchiveRegistry.delete_all
    end

    context "deleting data" do
      context "on success" do
        it "deletes Users" do
          expect {
            archive
          }.to change { User.count }.from(190).to(90)
        end
      end

      context "on failure" do
        before do
          allow_any_instance_of(Tartarus::RemoteStorage::Glacier).to receive(:store) { raise "whoops" }
        end

        it "does not delete anything if Glacier upload blows up" do
          expect {
            archive rescue nil
          }.not_to change { User.count }
        end
      end
    end

    describe "uploading to Glacier" do
      context "on success" do
        it "uploads exported CSV file to Glacier" do
          archive

          assert_requested(:post, "https://glacier.#{aws_region}.amazonaws.com/-/vaults/#{vault_name}/archives") do |req|
            rows_count = req.body.split("\n").count
            req.body.include?(csv_headers) && req.body.include?(csv_body_part) && rows_count == expected_numbers_of_rows_in_csv_file
          end
        end
      end

      it "creates ArchiveRegistry record with all the important attributes" do
        expect {
          archive
        }.to change { ArchiveRegistry.count }.by(1)

        expect(created_archive_registry.attributes.except("id", "created_at", "updated_at")).to eq(
          "archivable_model" => "User",
          "completed_at" => Time.now,
          "glacier_archive_id" => "BIFhTIYTIVJ8bRgQ3ZLhGh9RNJdR8TQbKUKKh56Dn1EuAf3QFxBnFUyczJ9gfqq2IcFMnQOH9bX_I_IGetM49cmcWisUp6p9Heso3pGzzghVuF3aFIXdsNRSTFZ1dc3Hff_-FYPmpg",
          "glacier_checksum" => "965c1ae80ca029483f4139126588d3fb73e5448a6f86e8c952793e7e92bb2616",
          "glacier_location" => "/441911171826/vaults/#{vault_name}/archives/BIFhTIYTIVJ8bRgQ3ZLhGh9RNJdR8TQbKUKKh56Dn1EuAf3QFxBnFUyczJ9gfqq2IcFMnQOH9bX_I_IGetM49cmcWisUp6p9Heso3pGzzghVuF3aFIXdsNRSTFZ1dc3Hff_-FYPmpg",
          "tenant_id" => "Partition_1",
          "tenant_id_field" => "partition_name"
        )
      end
    end
  end

  context "without tenant" do
    subject(:archive) do
      Tartarus::ArchiveModelWithoutTenant.new(registry: registry).archive("User")
    end

    let(:registry) { Tartarus::Registry.new }
    let(:archivable_item) do
      Tartarus::ArchivableItem.new.tap do |item|
        item.model = User
        item.timestamp_field = :created_at
        item.archive_items_older_than = -> { Date.today }
        item.archive_with = :delete_all_using_limit_in_batches
        item.batch_size = 20
        item.remote_storage = Tartarus::RemoteStorage::Glacier.new(glacier_configuration)
      end
    end
    let(:glacier_configuration) do
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
    let(:csv_body_part) { "#{User.maximum(:id) - 41};2020-01-01 12:00:00;Partition_2" } # first 150 records were deleted, so we need the last previous ID
    let(:created_archive_registry) { ArchiveRegistry.last }
    let(:expected_numbers_of_rows_in_csv_file) { 1 + 150 } # headers + deleted rows

    before do
      registry.register(archivable_item)

      User.delete_all

      100.times { User.create!(created_at: Time.new(2020, 1, 1, 12, 0, 0, 0), partition_name: "Partition_1") }
      50.times { User.create!(created_at: Time.new(2020, 1, 1, 12, 0, 0, 0), partition_name: "Partition_2") }
      20.times { User.create!(created_at: Time.new(2030, 1, 1, 12, 0, 0, 0), partition_name: "Partition_1") }
      20.times { User.create!(created_at: Time.new(2030, 1, 1, 12, 0, 0, 0), partition_name: "Partition_2") }
    end

    around do |example|
      VCR.use_cassette("Archiving_With_Glacier_Upload_without_tenant") do
        example.run
      end
    end

    after do
      User.delete_all
      ArchiveRegistry.delete_all
    end

    context "deleting data" do
      context "on success" do
        it "deletes Users" do
          expect {
            archive
          }.to change { User.count }.from(190).to(40)
        end
      end

      context "on failure" do
        before do
          allow_any_instance_of(Tartarus::RemoteStorage::Glacier).to receive(:store) { raise "whoops" }
        end

        it "does not delete anything if Glacier upload blows up" do
          expect {
            archive rescue nil
          }.not_to change { User.count }
        end
      end
    end

    describe "uploading to Glacier" do
      context "on success" do
        it "uploads exported CSV file to Glacier" do
          archive

          assert_requested(:post, "https://glacier.#{aws_region}.amazonaws.com/-/vaults/#{vault_name}/archives") do |req|
            rows = req.body.split("\n").count
            req.body.include?(csv_headers) && req.body.include?(csv_body_part) &&  rows == expected_numbers_of_rows_in_csv_file
          end
        end
      end

      it "creates ArchiveRegistry record with all the important attributes" do
        expect {
          archive
        }.to change { ArchiveRegistry.count }.by(1)

        expect(created_archive_registry.attributes.except("id", "created_at", "updated_at")).to eq(
          "archivable_model" => "User",
          "completed_at" => Time.now,
          "glacier_archive_id" => "Iy66HBY14A7Or6bdKql6gtN21SUJ1uHLmsaTosQjmDsKuslMBmFmukQIQ0xRwHeGkqGXAzcU04-9GhQVyBpRB0bSJ1jQ0XetlJgvhf5IZ-IVpkR0JKfcOyb-QgYdq67XzWp_Iax5Lw",
          "glacier_checksum" => "3f64e797a2c52fb6f8c706efedbfa9b269809fdbdd38b8f05f0989f7c8f53124",
          "glacier_location" => "/441911171826/vaults/#{vault_name}/archives/Iy66HBY14A7Or6bdKql6gtN21SUJ1uHLmsaTosQjmDsKuslMBmFmukQIQ0xRwHeGkqGXAzcU04-9GhQVyBpRB0bSJ1jQ0XetlJgvhf5IZ-IVpkR0JKfcOyb-QgYdq67XzWp_Iax5Lw",
          "tenant_id" => nil,
          "tenant_id_field" => nil
        )
      end
    end
  end
end
