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

  tartarus.register do |item|
    item.model = YetAnotherModel
    item.cron = "5 6 * * *"
    item.queue = "default"
    item.timestamp_field = :created_at
    item.archive_items_older_than = -> { 1.week.ago }
  end

  tartarus.schedule #  this method must be called to create jobs for sidekiq-cron!
end
```


You can use the following config params:
- `model` - a name of the ActiveReord model you want to archive, required
- `cron` - cron syntax, required
- `queue` - name of the sidekiq queue you want to use for execution of the jobs, required
- `tenants_range` - optional, use if you want to scope items by a tenant (or any field that can be used for partitioning). It doesn't have to be ActiveRecord collection, could be just an array. Must be a proc/lambda/object responding to `call` method. For ActvieRecord collection, `find_each` loop will be used for optimization.
- `tenant_value_source` - optional but required if you want to have scoping by tenant/partitioning field. Specifying `:uuid` here means that ModelThatYouWantToArchive collection will be scheduled for archiving by uuid of each Account. It defaults to `id`.
- `tenant_id_field` - required when using tenant_value_source/tenant_value_source. It's a DB column that will be used for scoping records by a tenant. For example, here it would be: `ModelThatYouWantToArchive.where(account_uuid: value_of_uuid_from_some_active_account)`
- `archive_items_older_than` - required, for defining retention policy
- `timestamp_field` - required, used for performing a query using the value from `archive_items_older_than`
- `archive_with` - optional (defaults to `delete_all`). Could be `delete_all`, `destroy_all`, `delete_all_without_batches`, `destroy_all_without_batches`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## TODO

- add support for uploading archives to AWS Glacier before deleting items

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tartarus-rb.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
