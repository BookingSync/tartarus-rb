class Tartarus::ScheduleArchivingModel
  attr_reader :registry
  private     :registry

  def initialize(registry: Tartarus.registry)
    @registry = registry
  end

  def schedule(archivable_item_name)
    archivable_item = registry.find_by_name(archivable_item_name)

    if archivable_item.scope_by_tenant?
      each_tenant(archivable_item) do |tenant|
        enqueue(Tartarus::Sidekiq::ArchiveModelWithTenantJob, archivable_item.queue, archivable_item.name, tenant)
      end
    else
      enqueue(Tartarus::Sidekiq::ArchiveModelWithoutTenantJob, archivable_item.queue, archivable_item.name)
    end
  end

  private

  def each_tenant(archivable_item)
    collection = archivable_item.tenants_range.call

    if collection.respond_to?(:find_each)
      collection.find_each { |element| yield element.public_send(archivable_item.tenant_value_source) }
    else
      collection.each { |element| yield element }
    end
  end

  def enqueue(job_class, queue, *args)
    job_class.set(queue: queue).perform_async(*args)
  end
end
