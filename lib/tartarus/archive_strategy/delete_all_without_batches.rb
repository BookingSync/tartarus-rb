class Tartarus
  class ArchiveStrategy
    class DeleteAllWithoutBatches
      def call(collection)
        collection.delete_all
      end
    end
  end
end
