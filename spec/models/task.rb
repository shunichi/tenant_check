# frozen_string_literal: true

class Task < ActiveRecord::Base
  belongs_to :tenant
  belongs_to :user
end
