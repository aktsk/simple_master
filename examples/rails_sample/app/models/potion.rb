# frozen_string_literal: true

class Potion < ApplicationMaster
  include ItemReceivable

  def_column :id
  def_column :name
  def_column :hp, type: :float

  globalize :name

  validates :name, presence: true
  validates :hp, numericality: { greater_than_or_equal_to: 0 }
end
