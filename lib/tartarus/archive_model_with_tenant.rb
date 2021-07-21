class Tartarus::ArchiveModelWithTenant
  attr_reader :registry, :repository
  private     :registry, :repository

  def initialize(registry: Tartarus.registry, repository: Tartarus::ArchivableCollectionRepository.new)
    @registry = registry
    @repository = repository
  end

  def archive(archivable_item_name, tenant_id)
    archivable_item = registry.find_by_name(archivable_item_name)
    collection = collection_to_archive(archivable_item, tenant_id)
    archivable_item.remote_storage.store(collection, archivable_item.name, tenant_id: tenant_id,
      tenant_id_field: archivable_item.tenant_id_field)
    archivable_item.archive_strategy.call(collection)
  end

  private

  def collection_to_archive(archivable_item, tenant_id)
    repository
      .items_older_than_for_tenant(
        archivable_item.model,
        archivable_item.timestamp_field, archivable_item.archive_items_older_than.call,
        archivable_item.tenant_id_field, tenant_id
      )
  end
end
