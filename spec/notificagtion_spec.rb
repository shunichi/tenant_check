# frozen_string_literal: true

RSpec.describe 'Notifications' do
  let(:middleware) { TenantCheck::Rack.new(app) }
  let(:app) { Support::FakeApp.new('<html><head></head><body></body></html>') { User.first } }

  context 'when TenantCheck.raise_error is truthy' do
    around do |ex|
      prev_logger = TenantCheck.logger
      TenantCheck.logger = Logger.new('/dev/null')
      TenantCheck.raise_error = true
      ex.run
      TenantCheck.raise_error = false
      TenantCheck.logger = prev_logger
    end

    it 'raise error' do
      expect {
        middleware.call({})
      }.to raise_error(TenantCheck::UnsafeQueryError)
    end
  end

  context 'when TenantCheck.logger is set' do
    let(:string_io) { StringIO.new }

    around do |ex|
      prev_logger = TenantCheck.logger
      TenantCheck.logger = Logger.new(string_io)
      ex.run
      TenantCheck.logger = prev_logger
    end

    it 'output notification to logger' do
      expect {
        middleware.call({})
      }.to change(string_io, :string)
      expect(string_io.string).to match(/Query without tenant condition detected!/)
      expect(string_io.string).to match(/sql: SELECT +"users"\.\* FROM "users" ORDER BY "users"\."id" ASC LIMIT 1/)
    end
  end
end
