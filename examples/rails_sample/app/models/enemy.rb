# frozen_string_literal: true

class Enemy < ApplicationMaster
  def_column :id
  def_column :name, type: :string
  def_column :is_boss, type: :boolean
  def_column :start_at, type: :time
  def_column :end_at, type: :time, group_key: true
  def_column :attack, type: :float
  def_column :defence, type: :float
  def_column :hp, type: :float
  def_column :exp, type: :integer
  def_column :stamina_cost, type: :integer

  has_many :rewards

  validates :name, presence: true
  validates :attack, :defence, :hp, numericality: { greater_than_or_equal_to: 0 }
  validates :exp, :stamina_cost, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :end_after_start_at

  cache_class_method def self.sorted_end_ats
    # end_atを降順でソートした配列
    [nil, *grouped_hash[:end_at].keys.compact.sort!.reverse!]
  end

  def self.not_ended(time = Time.current)
    sorted_end_ats
      .take_while { |end_at| end_at.nil? || end_at > time }
      .flat_map { |end_at| all_by(:end_at, end_at) }
  end

  def self.available_at(time = Time.current)
    not_ended(time).filter { _1.has_started?(time) }
  end

  def has_started?(time = Time.current)
    start_at.nil? || start_at <= time
  end

  def not_ended?(time = Time.current)
    end_at.nil? || end_at > time
  end

  def available?(time = Time.current)
    has_started?(time) && not_ended?(time)
  end

  private

  def end_after_start_at
    return if start_at.nil? || end_at.nil?
    return if end_at > start_at

    errors.add(:end_at, :invalid)
  end
end
