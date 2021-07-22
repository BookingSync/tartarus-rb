require "sidekiq"

class Tartarus
  class Sidekiq::ArchiveModelWithoutTenantJob
    include ::Sidekiq::Worker

    def perform(archivable_item_name)
      Tartarus::ArchiveModelWithoutTenant.new.archive(archivable_item_name)
    end
  end
end
