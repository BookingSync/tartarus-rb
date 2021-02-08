RSpec.describe Tartarus::RemoteStorage::Glacier::Client do
  describe "#upload_archive" do
    subject(:upload_archive) { client.upload_archive(vault_name, file) }

    let(:client) { described_class.new(key: aws_key, secret: aws_secret, region: aws_region, account_id: "-") }
    let(:aws_key) { ENV.fetch("AWS_KEY") }
    let(:aws_secret) { ENV.fetch("AWS_SECRET") }
    let(:aws_region) { ENV.fetch("AWS_REGION") }
    let(:vault_name) { ENV.fetch("VAULT_NAME") }
    let(:file) { double(:file, description: "Tartarus file", body: "body") }

    around do |example|
      VCR.use_cassette(described_class.to_s) do
        example.run
      end
    end

    it "uploads given file to Glacier" do
      upload_archive

      assert_requested :post, "https://glacier.#{aws_region}.amazonaws.com/-/vaults/#{vault_name}/archives",
        body: "body"
    end

    it "returns response with some useful data" do
      expect(upload_archive.location).to eq "/441911171826/vaults/VAULT_NAME/archives/evQkWS6TGS0VR2tGEjcKBqTuIHI0McRk0uHbEA2ksQcUr28-ajzOlXHkIuC96y1dpzGmA6uLMPAcic8o3R3T88cZc1Fc3mB-BF_UHYCvf-1BIxXH1l7sEcQnspg1rsmlZ5soHp0i-A"
      expect(upload_archive.checksum).to eq "230d8358dc8e8890b4c58deeb62912ee2f20357ae92a5cc861b98e68fe31acb5"
      expect(upload_archive.archive_id).to eq "evQkWS6TGS0VR2tGEjcKBqTuIHI0McRk0uHbEA2ksQcUr28-ajzOlXHkIuC96y1dpzGmA6uLMPAcic8o3R3T88cZc1Fc3mB-BF_UHYCvf-1BIxXH1l7sEcQnspg1rsmlZ5soHp0i-A"
    end
  end
end
