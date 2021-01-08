class Tartarus
  class ArchiveStrategy
    class DeleteAllUsingLimitInBatches
      attr_reader :batch_size
      private     :batch_size

      def initialize(batch_size:)
        @batch_size = batch_size
      end

      def call(collection)
        num = 1

        while num > 0
          num = collection.limit(batch_size).delete_all
        end
      end
    end
  end
end
