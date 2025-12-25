# frozen_string_literal: true

class Reward < ApplicationMaster
  def_column :id
  def_column :enemy_id, type: :integer, group_key: true
  def_column :reward_type, polymorphic_type: true, group_key: true
  def_column :reward_id, type: :integer

  belongs_to :enemy
  belongs_to :reward, polymorphic: true

  validates :reward_type, presence: true
  validate :reward_type_receivable

  private

  def reward_type_receivable
    klass = reward_type.safe_constantize
    return if klass && klass <= ItemReceivable

    errors.add(:reward_type, :invalid)
  end
end
