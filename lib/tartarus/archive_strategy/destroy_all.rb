class Tartarus
  class ArchiveStrategy
    class DestroyAll
      def call(collection)
        collection.destroy_all
      end
    end
  end
end
