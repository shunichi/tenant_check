# frozen_string_literal: true

RSpec.describe 'Internal flag' do
  describe '_tenant_check_safe' do
    it 'is true when finding a tenant record' do
      tenant = Tenant.first
      expect(tenant._tenant_check_safe).to eq true
    end

    it 'is falsey when finding a non-tenant record' do
      user = User.first
      expect(user._tenant_check_safe).to be_falsey
    end

    it 'is true when finding tenant records' do
      tenants = Tenant.all
      expect(tenants).to be_kind_of(ActiveRecord::Relation)
      expect(tenants).not_to be_kind_of(ActiveRecord::AssociationRelation)
      expect(tenants).not_to be_kind_of(ActiveRecord::Associations::CollectionProxy)
      expect(tenants.all?(&:_tenant_check_safe)).to eq true
    end

    it 'is falsey when finding non-tenant records' do
      users = User.all
      expect(users).to be_kind_of(ActiveRecord::Relation)
      expect(users).not_to be_kind_of(ActiveRecord::AssociationRelation)
      expect(users).not_to be_kind_of(ActiveRecord::Associations::CollectionProxy)
      expect(users.none?(&:_tenant_check_safe)).to eq true
    end

    it 'is true when the association relation is based on a tenant' do
      tenant = Tenant.first
      relation = tenant.tasks.where('id > 0')
      expect(relation).to be_kind_of(ActiveRecord::AssociationRelation)
      tasks = relation.to_a
      expect(tasks).not_to be_empty
      expect(tasks.all?(&:_tenant_check_safe)).to eq true
    end

    it 'is true when the association relation is based on safe record' do
      user = Tenant.first.users.first
      expect(user._tenant_check_safe).to eq true
      relation = user.tasks.where('id > 0')
      expect(relation).to be_kind_of(ActiveRecord::AssociationRelation)
      tasks = relation.to_a
      expect(tasks).not_to be_empty
      expect(tasks.all?(&:_tenant_check_safe)).to eq true
    end

    it 'is false when the association relation is based on unsafe record' do
      user = User.first
      expect(user._tenant_check_safe).to be_falsey
      relation = user.tasks.where('id > 0')
      expect(relation).to be_kind_of(ActiveRecord::AssociationRelation)
      tasks = relation.to_a
      expect(tasks).not_to be_empty
      expect(tasks.none?(&:_tenant_check_safe)).to eq true
    end

    it 'is true when the collection proxy is based on a tenant' do
      tenant = Tenant.first
      relation = tenant.tasks
      expect(relation).to be_kind_of(ActiveRecord::Associations::CollectionProxy)
      tasks = relation.to_a
      expect(tasks.all?(&:_tenant_check_safe)).to eq true
    end

    it 'is true when the collection proxy is based on safe record' do
      user = Tenant.first.users.first
      expect(user._tenant_check_safe).to eq true
      relation = user.tasks
      expect(relation).to be_kind_of(ActiveRecord::Associations::CollectionProxy)
      tasks = relation.to_a
      expect(tasks.all?(&:_tenant_check_safe)).to eq true
    end

    it 'is false when the collection proxy is based on unsafe record' do
      user = User.first
      expect(user._tenant_check_safe).to be_falsey
      relation = user.tasks
      expect(relation).to be_kind_of(ActiveRecord::Associations::CollectionProxy)
      tasks = relation.to_a
      expect(tasks).not_to be_empty
      expect(tasks.none?(&:_tenant_check_safe)).to eq true
    end

    it 'is true when belongs_to association owner is safe' do
      tenant = Tenant.first
      task = tenant.tasks.first
      user = task.user
      expect(user._tenant_check_safe).to eq true
    end

    it 'is falsey when belongs_to association owner is unsafe' do
      task = Task.first
      expect(task._tenant_check_safe).to be_falsey
      user = task.reload.user
      expect(user._tenant_check_safe).to be_falsey
    end

    # TODO: test belongs_to polymorphic association
    # TODO: test has_one association
    # TODO: test has_one_through association
  end
end
