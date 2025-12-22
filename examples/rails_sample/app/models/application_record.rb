# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  include SimpleMaster::ActiveRecord::Extension
end
