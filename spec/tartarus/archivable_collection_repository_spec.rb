RSpec.describe Tartarus::ArchivableCollectionRepository do
  describe "#items_older_than_for_tenant" do
    subject(:items_older_than_for_tenant) do
      repository.items_older_than_for_tenant(model_name, timestamp_field, timestamp, tenant_id_field, tenant_id)
    end

    let(:repository) { described_class.new(const_resolver: const_resolver) }
    let(:model_name) { "ModelName" }
    let(:timestamp_field) { :created_at }
    let(:timestamp) { "2020-01-01" }
    let(:tenant_id_field) { "tenant_id" }
    let(:tenant_id) { 22 }

    context "when timestamp field does not exist" do
      let(:column_names) { ["id", "tenant_id"] }

      it { is_expected_block.to raise_error "column :created_at does not exist for ModelName" }
    end

    context "when tenant id field does not exist" do
      let(:column_names) { ["id", "created_at"] }

      it { is_expected_block.to raise_error "column :tenant_id does not exist for ModelName" }
    end

    context "when timestamp and tenant id columns exist" do
      let(:column_names) { ["id", "created_at", "tenant_id"] }

      let(:expected_where_statements) do
        [
          ["created_at < ?", "2020-01-01"],
          [{ "tenant_id" => 22 }]
        ]
      end

      it "queries the target collection using ActiveRecord-like interface returning the collection" do
        expect {
          items_older_than_for_tenant
        }.to change { collection.where_statements }.from([]).to(expected_where_statements)
      end

      it "returns the collection" do
        expect(items_older_than_for_tenant).to eq collection
      end
    end
  end

  describe "#items_older_than" do
    subject(:items_older_than) do
      repository.items_older_than(model_name, timestamp_field, timestamp)
    end

    let(:repository) { described_class.new(const_resolver: const_resolver) }
    let(:model_name) { "ModelName" }
    let(:timestamp_field) { :created_at }
    let(:timestamp) { "2020-01-01" }

    context "when timestamp field does not exist" do
      let(:column_names) { ["id", "tenant_id"] }

      it { is_expected_block.to raise_error "column :created_at does not exist for ModelName" }
    end

    context "when timestamp field exists" do
      let(:column_names) { ["id", "created_at"] }

      let(:expected_where_statements) do
        [
          ["created_at < ?", "2020-01-01"]
        ]
      end

      it "queries the target collection using ActiveRecord-like interface returning the collection" do
        expect {
          items_older_than
        }.to change { collection.where_statements }.from([]).to(expected_where_statements)
      end

      it "returns the collection" do
        expect(items_older_than).to eq collection
      end
    end
  end

  describe "default const_resolver" do
    subject(:trigger_const_get_usage) do
      described_class.new.items_older_than(model_name, double, double)
    end

    let(:model_name) { "ModelName" }

    it "uses Object.const_get" do
      expect {
        trigger_const_get_usage
      }.to raise_error "uninitialized constant ModelName"
    end
  end

  let(:const_resolver) do
    Class.new do
      attr_reader :expected_model_name, :resolved_const
      private     :expected_model_name, :resolved_const

      def initialize(expected_model_name, resolved_const)
        @expected_model_name = expected_model_name
        @resolved_const = resolved_const
      end

      def const_get(model_name)
        raise "invalid setup" if model_name != expected_model_name

        resolved_const
      end
    end.new(model_name, collection)
  end
  let(:collection) do
    Class.new do
      attr_reader :column_names, :where_statements

      def initialize(column_names)
        @column_names = column_names
        @where_statements = []
      end

      def where(*args)
        @where_statements << [*args]
        self
      end
    end.new(column_names)
  end
end
