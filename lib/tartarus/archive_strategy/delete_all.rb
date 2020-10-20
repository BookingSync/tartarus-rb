class Tartarus::ArchiveStrategy::DeleteAll
  def call(collection)
    collection.delete_all
  end
end
