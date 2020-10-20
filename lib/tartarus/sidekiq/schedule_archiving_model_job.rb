require "sidekiq"

class Tartarus
  class Sidekiq::ScheduleArchivingModelJob
    include ::Sidekiq::Worker

    def perform(model_name)
      Tartarus::ScheduleArchivingModel.new.schedule(model_name)
    end
  end
end
