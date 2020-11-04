class Tartarus
  class ArchiveStrategy
    class DestroyAll
      def call(collection)
        Tartarus::ArchiveStrategy::ExtractBatch.new.call(collection) do |batch|
          batch.destroy_all
        end
      end
    end
  end
end
