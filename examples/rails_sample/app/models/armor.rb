# frozen_string_literal: true

class Armor < ApplicationMaster
  include ItemReceivable

  def_column :id
  def_column :icon, type: :string
  def_column :name, type: :string
  def_column :defence, type: :float

  validates :name, presence: true
  validates :defence, numericality: { greater_than_or_equal_to: 0 }

  def self.max_quantity
    1
  end
end
