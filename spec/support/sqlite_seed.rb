# frozen_string_literal: true

module Support
  module SqliteSeed
    module_function

    def seed_db
      tenant_1 = Tenant.create!(name: 'tenant 1')
      tenant_2 = Tenant.create!(name: 'tenant 2')

      user_1_1 = tenant_1.users.create!(name: 'user 1-1')
      user_1_2 = tenant_1.users.create!(name: 'user 1-2') # rubocop:disable Lint/UselessAssignment
      user_2_1 = tenant_2.users.create!(name: 'user 2-1') # rubocop:disable Lint/UselessAssignment

      tenant_1.tasks.create!(title: 'task 1-1', user: user_1_1)
      tenant_1.tasks.create!(title: 'task 1-2', user: user_1_1)
      tenant_2.tasks.create!(title: 'task 2-1')
    end

    def setup_db
      ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

      ActiveRecord::Schema.define(version: 1) do
        create_table :tenants do |t|
          t.column :name, :string
        end

        create_table :users do |t|
          t.column :tenant_id, :integer
          t.column :name, :string
        end

        create_table :tasks do |t|
          t.column :tenant_id, :integer
          t.column :user_id, :integer
          t.column :title, :string
        end
      end
    end
  end
end
