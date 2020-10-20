class Tartarus
  class ArchiveStrategy
    class DeleteAll
      def call(collection)
        collection.delete_all
      end
    end
  end
end
