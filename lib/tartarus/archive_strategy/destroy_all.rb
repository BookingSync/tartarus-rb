class Tartarus::ArchiveStrategy::DestroyAll
  def call(collection)
    collection.destroy_all
  end
end
