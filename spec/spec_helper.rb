require "bundler/setup"
require "tartarus-rb"
require "rspec-sidekiq"
require "active_record"
require "webmock/rspec"
require "vcr"
require "dotenv/load"
require "postgres-copy"
require "timecop"

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:example, :freeze_time) do |example|
    freeze_time = example.metadata[:freeze_time]
    time_now = freeze_time == true ? Time.now.round : freeze_time
    Timecop.freeze(time_now) { example.run }
  end

  database_url = ENV.fetch("DATABASE_URL", "postgresql://localhost/tartarus-rb")
  ActiveRecord::Base.establish_connection(database_url)
  begin
    ActiveRecord::Base.connection.verify!
  rescue ActiveRecord::NoDatabaseError
    ActiveRecord::Base.establish_connection(database_url.sub(/\/[^\/]+$/, "/postgres"))
    ActiveRecord::Base.connection.create_database("tartarus-rb")
    ActiveRecord::Base.establish_connection(database_url)
  end

  ActiveRecord::Schema.define do
    create_table :users, force: true do |t|
      t.datetime :created_at, null: false
      t.string :partition_name, null: false
    end

    create_table :partitions, force: true do |t|
      t.string :name, null: false
    end

    create_table :archive_registries, force: true do |t|
      t.text :glacier_location, null: false
      t.text :glacier_checksum, null: false
      t.text :glacier_archive_id, null: false
      t.string :archivable_model, null: false
      t.string :tenant_id_field
      t.string :tenant_id
      t.datetime :completed_at, null: false
    end
  end

  class User < ActiveRecord::Base
    acts_as_copy_target
  end

  class UserWithoutInBatches < ActiveRecord::Base
    self.table_name = "users"
  end

  class Partition < ActiveRecord::Base
  end

  class ArchiveRegistry < ActiveRecord::Base
  end

  VCR.configure do |c|
    c.cassette_library_dir = "spec/assets/vcr_cassettes"
    c.ignore_localhost = true
    c.hook_into :webmock
    %w[AWS_KEY AWS_REGION AWS_SECRET VAULT_NAME].each do |sensitive_data|
      c.filter_sensitive_data("<#{sensitive_data}>") { ENV.fetch(sensitive_data) }
    end
    c.configure_rspec_metadata!
  end
end

RSpec::Matchers.define_negated_matcher :avoid_changing, :change
