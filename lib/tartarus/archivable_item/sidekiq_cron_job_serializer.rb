class Tartarus::ArchivableItem::SidekiqCronJobSerializer
  def serialize(archivable_item)
    {
      name: name_for_item(archivable_item),
      description: description_for_item(archivable_item),
      cron: archivable_item.cron,
      class: Tartarus::Sidekiq::ScheduleArchivingModelJob,
      args: [archivable_item.model],
      queue: archivable_item.queue,
      active_job: archivable_item.active_job
    }
  end

  private

  def name_for_item(archivable_item)
    "TARTARUS_#{archivable_item.model}"
  end

  def description_for_item(archivable_item)
    "[TARTARUS] Archiving Job for model: #{archivable_item.model}"
  end
end
