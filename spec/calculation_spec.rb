# frozen_string_literal: true

RSpec.describe 'Calculation methods' do
  %i[count average minimum maximum sum pluck].each do |operation|
    describe operation do
      it "creates a notification when #{operation} without tenant conditions" do
        expect {
          User.send(operation, :id)
        }.to change { TenantCheck.notifications.size }.by(1)
      end

      it "creates a notification when #{operation} with includes without tenant conditions" do
        expect {
          User.includes(:tasks).send(operation, :id)
        }.to change { TenantCheck.notifications.size }.by(1)
      end

      it "does not creates notifications when #{operation} based on tenant class" do
        expect {
          Tenant.send(operation, :id)
        }.not_to change { TenantCheck.notifications.size }
      end

      it "does not creates notifications when #{operation} on the collection proxy owned by a tenant record" do
        tenant = Tenant.first
        expect {
          tenant.tasks.send(operation, :id)
        }.not_to change { TenantCheck.notifications.size }
      end

      it "does not creates notifications when #{operation} on the association relation owned by a tenant record" do
        tenant = Tenant.first
        expect {
          tenant.tasks.where('id > 0').send(operation, :id)
        }.not_to change { TenantCheck.notifications.size }
      end

      it "does not creates notifications when #{operation} on the collection proxy owned by a safe record" do
        user = Tenant.first.users.first
        expect {
          user.tasks.send(operation, :id)
        }.not_to change { TenantCheck.notifications.size }
      end

      it "does not creates notifications when #{operation} on the association relation owned by a safe record" do
        user = Tenant.first.users.first
        expect {
          user.tasks.where('id > 0').send(operation, :id)
        }.not_to change { TenantCheck.notifications.size }
      end

      it "does not create notificaitons when #{operation} with marked as tenant safe" do
        expect {
          Task.mark_as_tenant_safe.send(operation, :id)
        }.not_to change { TenantCheck.notifications.size }
      end

      it "does not create notificaitons when eager_loading #{operation} with marked as tenant safe" do
        expect {
          Task.mark_as_tenant_safe.eager_load(:user).send(operation, :id)
        }.not_to change { TenantCheck.notifications.size }
      end
    end
  end
end
