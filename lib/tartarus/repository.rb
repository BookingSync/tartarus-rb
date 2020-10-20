class Tartarus::Repository
  attr_reader :backend, :serializer
  private     :backend, :serializer

  def initialize(backend: Sidekiq::Cron::Job, serializer: Tartarus::ArchivableItem::SidekiqCronJobSerializer.new)
    @backend = backend
    @serializer = serializer
  end

  def save(archivable_item)
    backend.new(serializer.serialize(archivable_item)).tap do |job|
      if job.valid?
        job.save
      else
        raise_invalid_job(job)
      end
    end
  end

  private

  def raise_invalid_job(job)
    errors = job.errors.join(",")
    raise "could not save job: #{errors}"
  end
end
