# frozen_string_literal: true

class PlayerItem < ApplicationRecord
  belongs_to :player
  belongs_to :item, polymorphic: true
end
