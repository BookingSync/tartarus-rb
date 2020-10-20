require "sidekiq"

class Tartarus
  class Sidekiq::ArchiveModelWithoutTenantJob
    include ::Sidekiq::Worker

    def perform(model_name)
      Tartarus::ArchiveModelWithoutTenant.new.archive(model_name)
    end
  end
end
