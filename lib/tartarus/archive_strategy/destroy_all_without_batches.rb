class Tartarus
  class ArchiveStrategy
    class DestroyAllWithoutBatches
      def call(collection)
        collection.destroy_all
      end
    end
  end
end
