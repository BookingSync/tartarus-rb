class Tartarus::ArchiveModelWithoutTenant
  attr_reader :registry, :repository
  private     :registry, :repository

  def initialize(registry: Tartarus.registry, repository: Tartarus::ArchivableCollectionRepository.new)
    @registry = registry
    @repository = repository
  end

  def archive(model_name)
    archivable_item = registry.find_by_model(model_name)
    collection = collection_to_archive(model_name, archivable_item)
    archivable_item.remote_storage.store(collection, model_name)
    archivable_item.archive_strategy.call(collection)
  end

  private

  def collection_to_archive(model_name, archivable_item)
    repository
      .items_older_than(
        model_name,
        archivable_item.timestamp_field, archivable_item.archive_items_older_than.call
      )
  end
end
