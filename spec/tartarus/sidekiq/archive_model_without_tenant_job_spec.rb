RSpec.describe Tartarus::Sidekiq::ArchiveModelWithoutTenantJob do
  describe "#perform" do
    subject(:perform) { described_class.new.perform(model_name) }

    let(:model_name) { "ModelNameForTestingArchiveModelWithoutTenantJob" }

    let(:registry) { Tartarus.registry }
    let(:tartarus) { Tartarus.new }
    let(:expected_where_statements) do
      [
        ["created_at < ?", Date.today],
        [{ "id" => ModelNameForTestingArchiveModelWithoutTenantJob }]
      ]
    end
    let(:expected_order) do
      [
        :created_at
      ]
    end

    around do |example|
      tartarus.register do |item|
        item.model = model_name
        item.cron = "* * * * *"
        item.timestamp_field = :created_at
        item.archive_items_older_than = -> { Date.today }
        item.queue = "default"
      end

      example.run

      registry.reset
    end

    it "calls Tartarus::ArchiveModelWithoutTenantJob#archive" do
      expect_any_instance_of(Tartarus::ArchiveModelWithoutTenant).to receive(:archive)
        .with(model_name).and_call_original

      expect {
        perform
      }.to change { ModelNameForTestingArchiveModelWithoutTenantJob.where_statements }.from([]).to(expected_where_statements)
      .and change { ModelNameForTestingArchiveModelWithoutTenantJob.order_by }.from([]).to(expected_order)
      .and change { ModelNameForTestingArchiveModelWithoutTenantJob.deleted? }.from(nil).to(true)
      .and change { ModelNameForTestingArchiveModelWithoutTenantJob.select_value }.from(nil).to("id")
    end
  end

  class ModelNameForTestingArchiveModelWithoutTenantJob
    def self.column_names
      %w(created_at)
    end

    def self.where_statements
      @where_statements ||= []
    end

    def self.order_by
      @order_by ||= []
    end

    def self.select_value
      @select_value
    end

    def self.where(*args)
      where_statements << [*args]
      self
    end

    def self.order(*args)
      @order_by = [*args]
      self
    end

    def self.primary_key
      "id"
    end

    def self.select(field)
      @select_value = field
      self
    end

    def self.find_in_batches
      yield self
    end

    def self.delete_all
      @deleted = true
    end

    def self.deleted?
      @deleted
    end
  end
end
