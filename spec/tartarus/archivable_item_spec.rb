RSpec.describe Tartarus::ArchivableItem do
  describe "attributes" do
    let(:archivable_item) { described_class.new }

    describe "model" do
      subject(:model) { archivable_item.model }

      context "when the attribute is not set" do
        it { is_expected.to eq nil }
      end

      context "when the attribute is set" do
        before do
          archivable_item.model = "model"
        end

        it { is_expected.to eq "model" }
      end
    end

    describe "queue" do
      subject(:queue) { archivable_item.queue }

      context "when the attribute is not set" do
        it { is_expected.to eq nil }
      end

      context "when the attribute is set" do
        before do
          archivable_item.queue = "queue"
        end

        it { is_expected.to eq "queue" }
      end
    end

    describe "cron" do
      subject(:cron) { archivable_item.cron }

      context "when the attribute is not set" do
        it { is_expected.to eq nil }
      end

      context "when the attribute is set" do
        context "when it's set to a valid cron value" do
          before do
            archivable_item.cron = "* * * * *"
          end

          it { is_expected.to eq "* * * * *" }
        end
      end

      context "when it's set to an invalid cron value" do
        subject(:set_cron_value) do
          archivable_item.cron = "whatever"
        end

        it { is_expected_block.to raise_error /invalid cron string/ }
      end
    end

    describe "tenants_range" do
      subject(:tenants_range) { archivable_item.tenants_range.call }

      context "when the attribute is not set" do
        it "returns a lambda returning an empty array" do
          expect(tenants_range).to eq []
        end
      end

      context "when the attribute is set" do
        context "when set as non-lambda" do
          subject(:set_tenants_range) do
            archivable_item.tenants_range = "tenants_range"
          end

          it { is_expected_block.to raise_error ":tenants_range must be a lambda" }
        end

        context "when set as lambda" do
          before do
            archivable_item.tenants_range = -> { "tenants_range" }
          end

          it { is_expected.to eq "tenants_range" }
        end
      end
    end

    describe "tenant_id_field" do
      subject(:tenant_id_field) { archivable_item.tenant_id_field }

      context "when the attribute is not set" do
        it { is_expected.to eq nil }
      end

      context "when the attribute is set" do
        before do
          archivable_item.tenant_id_field = "tenant_id_field"
        end

        it { is_expected.to eq "tenant_id_field" }
      end
    end

    describe "tenant_value_source" do
      subject(:tenant_value_source) { archivable_item.tenant_value_source }

      context "when the attribute is not set" do
        it { is_expected.to eq :id }
      end

      context "when the attribute is set" do
        before do
          archivable_item.tenant_value_source = "uuid"
        end

        it { is_expected.to eq "uuid" }
      end
    end

    describe "archive_items_older_than" do
      subject(:archive_items_older_than) { archivable_item.archive_items_older_than }

      context "when the attribute is not set" do
        it { is_expected.to eq nil }
      end

      context "when the attribute is set" do
        subject(:archive_items_older_than) { archivable_item.archive_items_older_than.call }

        context "when set as non-lambda" do
          subject(:set_archive_items_older_than) do
            archivable_item.archive_items_older_than = "archive_items_older_than"
          end

          it { is_expected_block.to raise_error ":archive_items_older_than must be a lambda" }
        end

        context "when set as lambda" do
          before do
            archivable_item.archive_items_older_than = -> { "archive_items_older_than" }
          end

          it { is_expected.to eq "archive_items_older_than" }
        end
      end
    end

    describe "timestamp_field" do
      subject(:timestamp_field) { archivable_item.timestamp_field }

      context "when the attribute is not set" do
        it { is_expected.to eq nil }
      end

      context "when the attribute is set" do
        before do
          archivable_item.timestamp_field = "timestamp_field"
        end

        it { is_expected.to eq "timestamp_field" }
      end
    end

    describe "active_job" do
      subject(:active_job) { archivable_item.active_job }

      context "when the attribute is not set" do
        it { is_expected.to eq false }
      end

      context "when the attribute is set" do
        before do
          archivable_item.active_job = true
        end

        it { is_expected.to eq true }
      end
    end

    describe "archive_with" do
      subject(:archive_with) { archivable_item.archive_with }

      context "when the attribute is not set" do
        it { is_expected.to eq :delete_all }
      end

      context "when the attribute is set" do
        before do
          archivable_item.archive_with = :destroy_all
        end

        it { is_expected.to eq :destroy_all }
      end
    end

    describe "batch_size" do
      subject(:batch_size) { archivable_item.batch_size }

      context "when the attribute is not set" do
        it { is_expected.to eq 10_000 }
      end

      context "when the attribute is set" do
        before do
          archivable_item.batch_size = 100
        end

        it { is_expected.to eq 100 }
      end
    end
  end

  describe "#validate!" do
    subject(:validate!) { archivable_item.validate! }

    let(:archivable_item) do
      described_class.new.tap do |item|
        item.model = model
        item.queue = queue
        item.cron = cron
        item.archive_items_older_than = archive_items_older_than
        item.timestamp_field = timestamp_field
        item.archive_with = archive_with
        item.tenant_value_source = tenant_value_source
      end
    end

    let(:model) { "model" }
    let(:queue) { "default" }
    let(:cron) { "* * * * *" }
    let(:archive_items_older_than) { -> {} }
    let(:timestamp_field) { :timestamp_field }
    let(:archive_with) { :destroy_all }
    let(:tenant_value_source) { :uuid }

    context "When all attributes are present" do
      it { is_expected_block.not_to raise_error }
    end

    context "When some attribute is not present" do
      context "when :model is not present" do
        let(:model) { nil }

        it { is_expected_block.to raise_error ":model must be present" }
      end

      context "when :queue is not present" do
        let(:queue) { nil }

        it { is_expected_block.to raise_error ":queue must be present" }
      end

      context "when :cron is not present" do
        let(:archivable_item) do
          described_class.new.tap do |item|
            item.model = model
            item.queue = queue
            item.archive_items_older_than = archive_items_older_than
            item.timestamp_field = timestamp_field
          end
        end

        it { is_expected_block.to raise_error ":cron must be present" }
      end

      context "when :archive_items_older_than is not present" do
        let(:archivable_item) do
          described_class.new.tap do |item|
            item.model = model
            item.queue = queue
            item.cron = cron
            item.timestamp_field = timestamp_field
          end
        end

        it { is_expected_block.to raise_error ":archive_items_older_than must be present" }
      end

      context "when :timestamp_field is not present" do
        let(:timestamp_field) { nil }

        it { is_expected_block.to raise_error ":timestamp_field must be present" }
      end

      context "when :archive_with is not present" do
        let(:archive_with) { nil }

        it { is_expected_block.to raise_error ":archive_with must be present" }
      end

      context "when :tenant_value_source is not present" do
        let(:tenant_value_source) { nil }

        it { is_expected_block.to raise_error ":tenant_value_source must be present" }
      end
    end
  end

  describe "#scope_by_tenant?" do
    subject(:scope_by_tenant?) { archivable_item.scope_by_tenant? }

    let(:archivable_item) do
      described_class.new.tap do |archivable_item|
        archivable_item.tenant_id_field = tenant_id_field
      end
    end

    context "when :tenant_id_field is set" do
      let(:tenant_id_field) { :account_id }

      it { is_expected.to eq true }
    end

    context "when :tenant_id_field is not set" do
      let(:tenant_id_field) { nil }

      it { is_expected.to eq false }
    end
  end

  describe "#archive_strategy" do
    subject(:archive_strategy) { archivable_item.archive_strategy }

    context "when :archive_with is :delete_all" do
      let(:archivable_item) { described_class.new }

      it { is_expected.to be_a Tartarus::ArchiveStrategy::DeleteAll }
    end

    context "when :archive_with is :destroy_all" do
      let(:archivable_item) do
        described_class.new.tap { |item| item.archive_with = :destroy_all }
      end

      it { is_expected.to be_a Tartarus::ArchiveStrategy::DestroyAll }
    end
  end

  describe "#for_model?" do
    subject(:for_model?) { archivable_item.for_model?(provided_model) }

    let(:archivable_item) { described_class.new.tap { |item| item.model = model } }
    let(:model) { "ModelName" }

    context "when provided model name is the one for which the item was created" do
      let(:provided_model) { double(to_s: model) }

      it { is_expected.to eq true }
    end

    context "when provided model name is not the one for which the item was created" do
      let(:provided_model) { double(to_s: "Other") }

      it { is_expected.to eq false }
    end
  end
end
