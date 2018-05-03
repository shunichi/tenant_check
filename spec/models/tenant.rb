# frozen_string_literal: true

class Tenant < ActiveRecord::Base
  has_many :tasks
  has_many :users
end
