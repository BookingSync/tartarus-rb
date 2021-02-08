RSpec.describe Tartarus::RemoteStorage::Glacier::File do
  describe "#description" do
    subject(:description) { glacier_file.description }

    let(:glacier_file) { described_class.new(file) }
    let(:file) { File.new("#{$LOAD_PATH.first}/fixtures/non_image_file.txt") }

    it { is_expected.to eq "non_image_file" }
  end

  describe "#body" do
    subject(:body) { glacier_file.body }

    let(:glacier_file) { described_class.new(file) }
    let(:file) { File.new("#{$LOAD_PATH.first}/fixtures/non_image_file.txt") }

    it { is_expected.to eq glacier_file }
  end

  describe "#checksum" do
    subject(:checksum) { glacier_file.checksum }

    let(:glacier_file) { described_class.new(file) }
    let(:file) { File.new("#{$LOAD_PATH.first}/fixtures/non_image_file.txt") }

    it { is_expected.to be_instance_of(Digest::SHA256) }
  end

  describe "#delete_from_local_storage" do
    subject(:delete_from_local_storage) { glacier_file.delete_from_local_storage }

    let(:glacier_file) { described_class.new(file) }
    let(:file) { File.new(file_path) }
    let(:storage_directory) { "/tmp" }
    let(:file_path) { "#{storage_directory}/glacier_file_#{timestamp}" }
    let!(:timestamp) { Time.now.to_i }
    let(:very_important_file_content) { "whatever" }

    before do
      FileUtils.mkdir_p(storage_directory) if !File.exist?(storage_directory)
      File.open(file_path, "w") { |f| f.write(very_important_file_content) }
    end

    it "deletes the file" do
      expect {
        delete_from_local_storage
      }.to change { File.exist?(file_path) }.from(true).to(false)
    end
  end
end
