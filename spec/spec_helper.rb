require "bundler/setup"
require "tartarus-rb"
require "rspec-sidekiq"
require "active_record"

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "spec/test.db")
  database = ActiveRecord::Base.connection

  database.drop_table(:users) if database.table_exists?(:users)
  database.drop_table(:partitions) if database.table_exists?(:partitions)

  database.create_table(:users) do |t|
    t.datetime :created_at, null: false
    t.string :partition_name, null: false
  end

  database.create_table(:partitions) do |t|
    t.string :name, null: false
  end

  class User < ActiveRecord::Base
  end

  class UserWithoutInBatches < ActiveRecord::Base
    self.table_name = "users"
  end

  class Partition < ActiveRecord::Base
  end
end

RSpec::Matchers.define_negated_matcher :avoid_changing, :change
