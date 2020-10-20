require "sidekiq"

class Tartarus::Sidekiq::ArchiveModelWithTenantJob
  include ::Sidekiq::Worker

  def perform(model_name, tenant_id)
    Tartarus::ArchiveModelWithTenant.new.archive(model_name, tenant_id)
  end
end
