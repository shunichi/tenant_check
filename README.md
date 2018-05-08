# TenantCheck

Detect tenant unsafe queries in Rails app.

## CAVEAT

This gem is in an early stage of development.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tenant_check'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tenant_check

## Usage

```ruby
# in config/initializers/tenant_check.rb
if Rails.env.development?
  TenantCheck.tenant_class = Tenant # your tenant class
  TenantCheck.enable = true
end
```

```ruby
class Tenant < ApplicationRecord
  has_many :users
  has_many :tasks
end

class Task < ApplicationRecord
  belongs_to :tenant
  belongs_to :user, optional: true
end

class User < ApplicationRecord
  belongs_to :tenant
  has_many :tasks
end
```

```ruby
# unsafe queries. (output warnings to log)
user = User.first # the query without tenant is unsafe.
user.tasks.to_a # the query based on unsafe record is unsafe.

# safe queries. (no warnings)
tenant = Tenant.first # tenant query is safe.
tenant_user = tenant.users.first # the query based on tenant is safe.
tenant_user.tasks.to_a # the query based on safe record is safe.
current_user.tasks.to_a # devise current_user is safe and the query based on it is safe.
```

### temporarlly disable tenant check

```ruby
users = TenantCheck.ignored { User.all.to_a }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## TODO
- test for various rails versions
- support calculation methods

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shunichi/tenant_check.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
