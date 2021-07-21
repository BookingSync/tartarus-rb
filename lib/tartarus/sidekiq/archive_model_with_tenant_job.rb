require "sidekiq"

class Tartarus
  class Sidekiq::ArchiveModelWithTenantJob
    include ::Sidekiq::Worker

    def perform(archivable_item_name, tenant_id)
      Tartarus::ArchiveModelWithTenant.new.archive(archivable_item_name, tenant_id)
    end
  end
end
