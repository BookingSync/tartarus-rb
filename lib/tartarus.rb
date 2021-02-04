require "tartarus/archivable_collection_repository"
require "tartarus/archivable_item"
require "tartarus/archivable_item/sidekiq_cron_job_serializer"
require "tartarus/archive_strategy"
require "tartarus/archive_strategy/delete_all"
require "tartarus/archive_strategy/delete_all_without_batches"
require "tartarus/archive_strategy/delete_all_using_limit_in_batches"
require "tartarus/archive_strategy/destroy_all"
require "tartarus/archive_strategy/destroy_all_without_batches"
require "tartarus/archive_strategy/extract_batch"
require "tartarus/sidekiq"
require "tartarus/sidekiq/archive_model_with_tenant_job"
require "tartarus/sidekiq/archive_model_without_tenant_job"
require "tartarus/sidekiq/schedule_archiving_model_job"
require "tartarus/archive_model_with_tenant"
require "tartarus/archive_model_without_tenant"
require "tartarus/rb/version"
require "tartarus/registry"
require "tartarus/repository"
require "tartarus/schedule_archiving_model"
require "tartarus/remote_storage"
require "tartarus/remote_storage/glacier"
require "tartarus/remote_storage/glacier/client"
require "tartarus/remote_storage/glacier/file"
require "tartarus/remote_storage/glacier/csv_export"
require "tartarus/remote_storage/glacier/register_upload"
require "tartarus/remote_storage/glacier/configuration"
require "sidekiq/cron/job"
require "aws-sdk-glacier"
require "sidekiq"

class Tartarus
  attr_reader :registry, :repository
  private     :registry, :repository

  def self.registry
    @registry ||= Tartarus::Registry.new
  end

  def initialize(repository: Tartarus::Repository.new(backend: ::Sidekiq::Cron::Job))
    @repository = repository
    @registry = self.class.registry
  end

  def register
    item = Tartarus::ArchivableItem.new
    yield item
    item.validate!

    registry.register(item)
  end

  def schedule
    registry.each { |item| repository.save(item) }
  end
end
