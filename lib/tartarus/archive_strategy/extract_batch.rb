class Tartarus
  class ArchiveStrategy
    class ExtractBatch
      def call(collection)
        primary_key = collection.primary_key

        collection.select(primary_key).find_in_batches do |group|
          yield collection.where(primary_key => group)
        end
      end
    end
  end
end
