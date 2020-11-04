RSpec.describe Tartarus::ArchiveStrategy::DestroyAll do
  describe "#call" do
    subject(:call) { described_class.new.call(collection) }

    context "when collection responds to :in_batches" do
      let(:collection) do
        Class.new do
          def initialize
            @destroyed = false
          end

          def destroyed?
            @destroyed
          end

          def destroy_all
            @destroyed = true
          end

          def in_batches
            self
          end
        end.new
      end

      it "calls :destroy_all on each batch" do
        expect {
          call
        }.to change { collection.destroyed? }.from(false).to(true)
      end
    end

    context "when collection does not respond to :in_batches (Rails 6)" do
      let(:collection) do
        Class.new do
          attr_reader :select_value, :where_value

          def initialize
            @destroyed = false
            @select_value = ""
            @where_value = {}
          end

          def destroyed?
            @destroyed
          end

          def destroy_all
            @destroyed = true
          end

          def primary_key
            "uuid"
          end

          def select(field)
            @select_value = field
            self
          end

          def find_in_batches
            yield self
          end

          def where(value)
            @where_value = value
            self
          end
        end.new
      end

      it "calls :destroy_all on each batch" do
        expect {
          call
        }.to change { collection.destroyed? }.from(false).to(true)
        .and change { collection.select_value }.from("").to("uuid")
        .and change { collection.where_value }.from({}).to("uuid" => collection)
      end
    end
  end
end
