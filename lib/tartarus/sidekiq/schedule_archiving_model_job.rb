require "sidekiq"

class Tartarus
  class Sidekiq::ScheduleArchivingModelJob
    include ::Sidekiq::Worker

    def perform(archivable_item_name)
      Tartarus::ScheduleArchivingModel.new.schedule(archivable_item_name)
    end
  end
end
