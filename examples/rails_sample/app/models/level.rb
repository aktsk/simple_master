# frozen_string_literal: true

class Level < ApplicationMaster
  def_column :id
  def_column :lv, type: :integer, group_key: true
  def_column :attack, type: :float
  def_column :defence, type: :float
  def_column :hp, type: :float
  def_column :next_exp, type: :integer
  def_column :hp_recovery_sec, type: :integer
  def_column :stamina, type: :integer
  def_column :stamina_recovery_sec, type: :integer

  has_many :players, foreign_key: :lv, primary_key: :lv

  validates :lv, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :attack, :defence, :hp, numericality: { greater_than_or_equal_to: 0 }
  validates :next_exp, :hp_recovery_sec, :stamina, :stamina_recovery_sec,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  cache_class_method def self.max_lv
    lvs = all.filter_map(&:lv)
    lvs.max || 0
  end

  def self.find_by_lv(lv)
    find_by(:lv, lv)
  end
end
