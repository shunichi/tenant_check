# frozen_string_literal: true

class User < ActiveRecord::Base
  belongs_to :tenant
  has_many :tasks
end
