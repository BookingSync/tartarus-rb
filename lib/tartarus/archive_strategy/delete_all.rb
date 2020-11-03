class Tartarus
  class ArchiveStrategy
    class DeleteAll
      def call(collection)
        primary_key = collection.primary_key

        collection.select(primary_key).find_in_batches do |group|
          collection.where(primary_key => group).delete_all
        end
      end
    end
  end
end
