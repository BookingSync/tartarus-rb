class Tartarus
  class ArchiveStrategy
    class DeleteAll
      def call(collection)
        Tartarus::ArchiveStrategy::ExtractBatch.new.call(collection) do |batch|
          batch.delete_all
        end
      end
    end
  end
end
