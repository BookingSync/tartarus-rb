class Tartarus
  class ArchiveStrategy
    class ExtractBatch
      attr_reader :config
      private     :config

      def initialize(config: Thread.current)
        @config = config
      end

      def call(collection)
        if collection.respond_to?(:in_batches) && !suppressed_in_batches?
          yield collection.in_batches
        else
          primary_key = collection.primary_key

          collection.select(primary_key).find_in_batches do |group|
            yield collection.where(primary_key => group)
          end
        end
      end

      def suppressed_in_batches?
        !!config["__TARTARUS__SUPPRESSED_IN_BATCHES"]
      end
    end
  end
end
