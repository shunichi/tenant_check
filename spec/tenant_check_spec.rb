# frozen_string_literal: true

RSpec.describe TenantCheck do
  it 'does not create notifications when the query is based on tenant class' do
    expect {
      Tenant.first
    }.not_to change { TenantCheck.notifications.size }
  end

  it 'does not create notifications when the query have a tenant condition' do
    tenant = Tenant.first
    expect {
      tenant.tasks.where(title: 'foo').to_a
    }.not_to change { TenantCheck.notifications.size }
  end

  it 'does not create notifications when the preload query have a tenant condition' do
    tenant = Tenant.first
    expect {
      tenant.tasks.preload(:user).to_a
    }.not_to change { TenantCheck.notifications.size }
  end

  it 'does not create notifications when the preload query have a tenant condition 2' do
    tenant = Tenant.first
    tasks = nil
    expect {
      tasks = tenant.tasks.where(title: 'task 1-1').includes(:user).to_a
    }.not_to change { TenantCheck.notifications.size }
    puts tasks.size
  end

  it 'creates a notificaiton when the query does not have a tenant condition' do
    expect {
      Task.all.to_a
    }.to change { TenantCheck.notifications.size }.by(1)
    expect {
      User.first
    }.to change { TenantCheck.notifications.size }.by(1)
  end

  it 'creates a notification when update_all method is called based on tenant unsafe relation' do
    expect {
      Task.update_all(title: 'foo')
    }.to change { TenantCheck.notifications.size }.by(1)
    expect(Task.pluck(:title)).to eq(['foo'] * 3)
  end

  it 'does not creates a notification when update_all method is called based on tenant safe relation' do
    tenant = Tenant.first
    expect {
      tenant.tasks.update_all(title: 'foo')
    }.not_to change { TenantCheck.notifications.size }
    expect(tenant.tasks.pluck(:title)).to eq(['foo'] * 2)
  end

  describe 'destroy_all' do
    it 'creates a notification when destroy_all methos is called based on tenant unsafe relation' do
      expect(Task.count).to eq 3
      expect {
        Task.destroy_all
      }.to change { TenantCheck.notifications.size }.by(1)
      expect(Task.count).to eq 0
    end

    it 'creates a notification when destroy_all methos is called based on tenant safe relation' do
      tenant = Tenant.first
      expect(tenant.tasks.count).to eq 2
      expect {
        tenant.tasks.destroy_all
      }.not_to change { TenantCheck.notifications.size }
      expect(tenant.tasks.count).to eq 0
    end
  end

  describe 'delete_all' do
    it 'creates a notification when delete_all methos is called based on tenant unsafe relation' do
      expect {
        Task.delete_all
      }.to change { TenantCheck.notifications.size }.by(1) & change(Task, :count).from(3).to(0)
    end

    it 'creates a notification when delete_all methos is called based on tenant safe relation' do
      tenant = Tenant.first
      expect {
        tenant.tasks.delete_all
      }.not_to change { TenantCheck.notifications.size }
      expect(tenant.tasks.count).to eq 0
    end
  end

  it 'creates only one notificaiton when queries have same call stacks' do
    expect {
      (1..2).each do |i|
        Task.where('id > ?', i).to_a
      end
    }.to change { TenantCheck.notifications.size }.by(1)
  end

  it 'creates a notification when eager load query without tenant conditions' do
    expect {
      Task.all.eager_load(:user).to_a
    }.to change { TenantCheck.notifications.size }.by(1)
  end

  it 'does not creates notifications when eager load query have a tenant condition' do
    tenant = Tenant.first
    expect {
      tenant.tasks.eager_load(:user).to_a
    }.not_to change { TenantCheck.notifications.size }
  end

  it 'does not create notificaitons when the query has a tenant condition' do
    expect {
      Task.where(tenant_id: 1).to_a
    }.not_to change { TenantCheck.notifications.size }
  end

  xdescribe 'Not implemented' do
    it 'does not create notificaitons when the query has join with target tenant' do
      expect {
        Task.joins(:tenant).merge(Tenant.where(id: 1)).to_a
      }.not_to change { TenantCheck.notifications.size }
    end
  end

  describe 'mark_as_tenant_safe' do
    it 'does not create notificaitons when the query is marked as tenant safe' do
      expect {
        Task.all.mark_as_tenant_safe.to_a
      }.not_to change { TenantCheck.notifications.size }
    end

    it 'does not create notificaitons when the query on a collection proxy is marked as tenant safe' do
      user = User.first
      expect {
        user.tasks.mark_as_tenant_safe.to_a
      }.not_to change { TenantCheck.notifications.size }
    end

    it 'does not create notificaitons when the query on a collection proxy is marked as tenant safe' do
      user = User.first
      expect {
        user.tasks.where('id > 0').mark_as_tenant_safe.to_a
      }.not_to change { TenantCheck.notifications.size }
    end

    it 'does not create notificaitons when the query based on a tenant safe marked record' do
      user = User.mark_as_tenant_safe.first
      expect {
        user.tasks.to_a
      }.not_to change { TenantCheck.notifications.size }
    end
  end

  context 'when safe_caller_patterns is set' do
    def my_safe_method
      Task.first
    end

    around do |ex|
      prev = TenantCheck.safe_caller_patterns
      TenantCheck.safe_caller_patterns = [/^.*`my_safe_method'.*$/]
      ex.run
      TenantCheck.safe_caller_patterns = prev
    end

    it 'does not creates notification when safe caller pattern matched' do
      expect {
        my_safe_method
      }.not_to change { TenantCheck.notifications.size }
    end
  end

  context 'when tenant_safe_classes is set' do
    around do |ex|
      TenantCheck.add_safe_classes(User)
      ex.run
      TenantCheck.safe_class_names.clear
    end

    it 'does not creates notification' do
      expect {
        User.first
      }.not_to change { TenantCheck.notifications.size }
    end
  end

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
  end
end
