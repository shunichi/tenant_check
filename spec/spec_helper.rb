# frozen_string_literal: true

require 'bundler/setup'
require 'tenant_check'
require 'active_record'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

MODELS = File.join(File.dirname(__FILE__), 'models')
$LOAD_PATH.unshift(MODELS)

ActiveRecord::Migration.verbose = false

Dir[File.join(MODELS, '*.rb')].sort.each do |filename|
  name = File.basename(filename, '.rb')
  autoload name.camelize.to_sym, name
end
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.before(:suite) do
    Support::SqliteSeed.setup_db
    ::TenantCheck.tenant_class = Tenant
    ::TenantCheck.enable = true
  end

  config.before do
    Support::SqliteSeed.clear_db
    Support::SqliteSeed.seed_db
    ::TenantCheck.start
  end
end
