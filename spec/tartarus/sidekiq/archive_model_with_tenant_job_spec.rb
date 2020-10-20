RSpec.describe Tartarus::Sidekiq::ArchiveModelWithTenantJob do
  describe "#perform" do
    subject(:perform) { described_class.new.perform(model_name, tenant_id) }

    let(:model_name) { "ModelNameForTestingArchiveModelWithTenantJob" }
    let(:tenant_id) { 1 }

    let(:registry) { Tartarus.registry }
    let(:tartarus) { Tartarus.new }
    let(:expected_where_statements) do
      [
        ["created_at < ?", Date.today],
        [{ tenant_id: 1 }]
      ]
    end

    around do |example|
      tartarus.register do |item|
        item.model = model_name
        item.cron = "* * * * *"
        item.timestamp_field = :created_at
        item.archive_items_older_than = -> { Date.today }
        item.tenant_id_field = :tenant_id
        item.queue = "default"
      end

      example.run

      registry.reset
    end

    it "calls Tartarus::ArchiveModelWithTenant#archive" do
      expect_any_instance_of(Tartarus::ArchiveModelWithTenant).to receive(:archive)
        .with(model_name, tenant_id).and_call_original

      expect {
        perform
      }.to change { ModelNameForTestingArchiveModelWithTenantJob.where_statements }.from([]).to(expected_where_statements)
      .and change { ModelNameForTestingArchiveModelWithTenantJob.deleted? }.from(nil).to(true)
    end
  end

  class ModelNameForTestingArchiveModelWithTenantJob
    def self.column_names
      %w(created_at tenant_id)
    end

    def self.where_statements
      @where_statements ||= []
    end

    def self.where(*args)
      where_statements << [*args]
      self
    end

    def self.delete_all
      @deleted = true
    end

    def self.deleted?
      @deleted
    end
  end
end
