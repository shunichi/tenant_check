# TenantCheck

Detect tenant unsafe queries in Rails app.

## CAVEAT

This gem is in an early stage of development.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tenant_check', group: :development
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tenant_check

## Usage

```ruby
# in config/environments/development.rb
config.after_initialize do
  TenantCheck.tenant_class = YourTenantClass
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## TODO
- uncheck query temporally
- test for various rails versions
- support `eager_load`
- support calculation methods

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shunichi/tenant_check.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
