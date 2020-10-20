class Tartarus::ArchiveModelWithTenant
  attr_reader :registry, :repository
  private     :registry, :repository

  def initialize(registry: Tartarus.registry, repository: Tartarus::ArchivableCollectionRepository.new)
    @registry = registry
    @repository = repository
  end

  def archive(model_name, tenant_id)
    archivable_item = registry.find_by_model(model_name)

    archivable_item.archive_strategy.call(collection_to_archive(model_name, archivable_item, tenant_id))
  end

  private

  def collection_to_archive(model_name, archivable_item, tenant_id)
    repository
      .items_older_than_for_tenant(
        model_name,
        archivable_item.timestamp_field, archivable_item.archive_items_older_than.call,
        archivable_item.tenant_id_field, tenant_id
      )
  end
end
