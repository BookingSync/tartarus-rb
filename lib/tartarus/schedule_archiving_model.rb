class Tartarus::ScheduleArchivingModel
  attr_reader :registry
  private     :registry

  def initialize(registry: Tartarus.registry)
    @registry = registry
  end

  def schedule(model_name)
    archivable_item = registry.find_by_model(model_name)

    if archivable_item.scope_by_tenant?
      each_tenant(archivable_item) do |tenant|
        enqueue(Tartarus::Sidekiq::ArchiveModelWithTenantJob, archivable_item.queue, model_name, tenant)
      end
    else
      enqueue(Tartarus::Sidekiq::ArchiveModelWithoutTenantJob, archivable_item.queue, model_name)
    end
  end

  private

  def each_tenant(archivable_item)
    collection = archivable_item.tenants_range.call

    if collection.respond_to?(:find_each)
      archivable_item.tenants_range
        .call
        .find_each { |element| yield element.public_send(archivable_item.tenant_value_source) }
    else
      collection.each { |element| yield element }
    end
  end

  def enqueue(job_class, queue, *args)
    job_class.set(queue: queue).perform_async(*args)
  end
end
