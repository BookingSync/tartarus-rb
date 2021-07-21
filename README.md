# Tartarus::Rb

A gem for archiving (deleting) old records you no longer need. Send them straight to tartarus!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tartarus-rb'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install tartarus-rb

## Usage

This game is based on sidekiq-cron, which means you can manage (e.g. disable/enable) jobs from sidekiq-cron UI.

Here are some examples how to use it

Put it in the initializer, e.g. in `config/initializers/sidekiq.rb` right after loading schedule for `sidekiq-cron`:

``` rb
schedule_file = "config/schedule.yml"

if File.exist?(schedule_file) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)

  tartarus = Tartarus.new

  tartarus.register do |item|
    item.model = ModelThatYouWantToArchive
    item.cron = "5 4 * * *"
    item.queue = "default"
    item.tenants_range = -> { Account.active }
    item.tenant_value_source = :uuid
    item.tenant_id_field = :account_uuid
    item.archive_items_older_than = -> { 30.days.ago }
    item.timestamp_field = :created_at
    item.archive_with = :destroy_all
  end

  tartarus.register do |item|
    item.model = OtherModelThatYouWantToArchive
    item.cron = "5 5 * * *"
    item.queue = "default"
    item.tenants_range = -> { ["Account", "User"] }
    item.tenant_id_field = :model_type
    item.archive_items_older_than = -> { 30.days.ago }
    item.timestamp_field = :created_at
  end

  glacier_configuration = Tartarus::RemoteStorage::Glacier::Configuration.build(
    aws_key: ENV.fetch("AWS_KEY"),
    aws_secret: ENV.fetch("AWS_SECRET"),
    aws_region: ENV.fetch("AWS_REGION"),
    vault_name: ENV.fetch("GLACIER_VAULT_NAME"),
    root_path: Rails.root.to_s,
    archive_registry_factory: ArchiveRegistry,
  )
  # don't forget about installing `aws-sdk-glacier` gem

  tartarus.register do |item|
    item.model = YetAnotherModel
    item.cron = "5 6 * * *"
    item.queue = "default"
    item.timestamp_field = :created_at
    item.archive_items_older_than = -> { 1.week.ago }
    item.remote_storage = Tartarus::RemoteStorage::Glacier.new(glacier_configuration)
  end

  tartarus.schedule #  this method must be called to create jobs for sidekiq-cron!
end
```


You can use the following config params:
- `model` - a name of the ActiveReord model you want to archive, required
- `name` - name of your strategy, optional. It fallbacks `model.to_s`. It's important to set in in cases when you have several strategies for the same model:
```rb
  tartarus.register do |item|
    item.model = InternalEvent
    item.name = "archive_account_and_user_internal_events"
    item.cron = "5 5 * * *"
    item.queue = "default"
    item.tenants_range = -> { ["Account", "User"] }
    item.tenant_id_field = :model_type
    item.archive_items_older_than = -> { 30.days.ago }
    item.timestamp_field = :created_at
  end

  tartarus.register do |item|
    item.model = InternalEvent
    item.name = "archive_post_and_comment_internal_events"
    item.cron = "5 15 * * *"
    item.queue = "default"
    item.tenants_range = -> { ["Post", "Comment"] }
    item.tenant_id_field = :model_type
    item.archive_items_older_than = -> { 10.days.ago }
    item.timestamp_field = :created_at
  end
```

- `cron` - cron syntax, required
- `queue` - name of the sidekiq queue you want to use for execution of the jobs, required
- `tenants_range` - optional, use if you want to scope items by a tenant (or any field that can be used for partitioning). It doesn't have to be ActiveRecord collection, could be just an array. Must be a proc/lambda/object responding to `call` method. For ActvieRecord collection, `find_each` loop will be used for optimization.
- `tenant_value_source` - optional but required if you want to have scoping by tenant/partitioning field. Specifying `:uuid` here means that ModelThatYouWantToArchive collection will be scheduled for archiving by uuid of each Account. It defaults to `id`.
- `tenant_id_field` - required when using tenant_value_source/tenant_value_source. It's a DB column that will be used for scoping records by a tenant. For example, here it would be: `ModelThatYouWantToArchive.where(account_uuid: value_of_uuid_from_some_active_account)`
- `archive_items_older_than` - required, for defining retention policy
- `timestamp_field` - required, used for performing a query using the value from `archive_items_older_than`
- `archive_with` - optional (defaults to `delete_all`). Could be `delete_all`, `destroy_all`, `delete_all_without_batches`, `destroy_all_without_batches`, `delete_all_using_limit_in_batches`
- `batch_size` - optional (defaults to `10_000`, used with `delete_all_using_limit_in_batches` strategy)
- `remote_storage` - optional (defaults to `Tartarus::RemoteStorage::Null` which does nothing). Use this option if you want store the data somewhere before deleting it.

### Remote Storage

Currently, only `Glacier` (for AWS Glacier) is supported. Also, it works only with Postgres database and requires [postgres-copy](https://github.com/diogob/postgres-copy).

To take advantage of this feature you will need a couple of things:
1. Apply `acts_as_copy_target` to the archivable model (from `postgres-copy` gem).
2. Create a model that will be used as a registry for all uploads that happened.
3. Install `aws-sdk-glacier` gem.

If you want to make `Version` model archivable and use `ArchiveRegistry` as the registry, you will need the following models and tables:

``` rb
database.create_table(:archive_registries) do |t|
  t.string :glacier_location, null: false
  t.string :glacier_checksum, null: false
  t.string :glacier_archive_id, null: false
  t.string :archivable_model, null: false
  t.string :tenant_id_field
  t.string :tenant_id
  t.datetime :completed_at, null: false
end

database.create_table(:versions) do |t|
end

class Version < ApplicationRecord
  acts_as_copy_target
end

class ArchiveRegistry < ApplicationRecord
end
```

You can use the above schema for the registry model as it contains all needed fields.

To initialize the service:

``` rb
glacier_configuration = Tartarus::RemoteStorage::Glacier::Configuration.build(
  aws_key: ENV.fetch("AWS_KEY"),
  aws_secret: ENV.fetch("AWS_SECRET"),
  aws_region: ENV.fetch("AWS_REGION"),
  vault_name: ENV.fetch("GLACIER_VAULT_NAME"),
  root_path: Rails.root.to_s,
  archive_registry_factory: ArchiveRegistry,
)
Tartarus::RemoteStorage::Glacier.new(glacier_configuration)
```

You can also pass `account_id` (by default "-" string will be used):

``` rb
glacier_configuration = Tartarus::RemoteStorage::Glacier::Configuration.build(
  aws_key: ENV.fetch("AWS_KEY"),
  aws_secret: ENV.fetch("AWS_SECRET"),
  aws_region: ENV.fetch("AWS_REGION"),
  vault_name: ENV.fetch("GLACIER_VAULT_NAME"),
  root_path: Rails.root.to_s,
  archive_registry_factory: ArchiveRegistry,
  account_id: "some_account_id"
)
Tartarus::RemoteStorage::Glacier.new(glacier_configuration)
```

**Important** - do not use Glacier Storage for large batches (> 4 GB) as multipart uploads are not supported yet.


If you know what you are doing, you can add your own storage, as long as it complies with the following interface:

``` rb
class Glacier
  attr_reader :configuration
  private     :configuration

  def initialize(configuration)
    @configuration = configuration
  end

  def store(collection, archivable_model, tenant_id: nil, tenant_id_field: nil)
  end
end
```

### Testing before actually using it

You might want to verify that the gem works in the way you expect it to work. For that, you will be mostly interested in 2 usecases:

1. scheduling/enqueueing: use `Tartarus::ScheduleArchivingModel#schedule` - for example, `Tartarus::ScheduleArchivingModel.new.schedule("PaperTrailVersion")`, it's going to enqueue either `Tartarus::Sidekiq::ArchiveModelWithTenantJob` or `Tartarus::Sidekiq::ArchiveModelWithoutTenantJob`, depending on the config.
2. execution of the archiving logic: use `Tartarus::ArchiveModelWithTenant#archive` (for example, `Tartarus::ArchiveModelWithTenant.new.archive("PaperTrailVersion", "User")`) or `Tartarus::ArchiveModelWithoutTenant#archive` (for example, `Tartarus::ArchiveModelWithoutTenant.new.archive("PaperTrailVersion")`)

You might also want to check `spec/integration` to get an idea how the integration tests were written.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tartarus-rb.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
