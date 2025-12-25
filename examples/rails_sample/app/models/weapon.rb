# frozen_string_literal: true

class Weapon < ApplicationMaster
  include ItemReceivable

  RARITY = {
    common: 0,
    rare: 1,
    epic: 2,
  }.freeze

  def_column :id
  def_column :type, sti: true
  def_column :icon, type: :string
  def_column :name, type: :string
  def_column :attack, type: :float
  def_column :info, type: :json, symbolize_names: true
  def_column :metadata, type: :json, symbolize_names: false
  def_column :rarity, type: :integer
  def_column :flags, type: :integer

  globalize :name

  enum :rarity, RARITY
  bitmask :flags, as: [:tradeable, :soulbound, :limited]

  validates :name, presence: true
  validates :attack, numericality: { greater_than_or_equal_to: 0 }
  validates :rarity, inclusion: { in: RARITY.keys }

  cache_method def cached_signature
    "#{name}-#{rarity}"
  end

  def self.max_quantity
    1
  end
end

class Gun < Weapon
end

class Blade < Weapon
end
