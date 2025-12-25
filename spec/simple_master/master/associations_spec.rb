# frozen_string_literal: true

require "spec_helper"

RSpec.describe "associations" do
  before { reset_active_record_tables }

  describe "belongs_to (master)" do
    it "works correctly" do
      reward = Reward.find(1)

      expect(reward.enemy).to eq(Enemy.find(1))
    end
  end

  describe "belongs_to (polymorphic master)" do
    it "works correctly" do
      reward = Reward.find(3)

      expect(reward.reward).to eq(Potion.find(2))
    end
  end

  describe "has_many (master)" do
    it "works correctly" do
      enemy = Enemy.find(1)

      expect(enemy.rewards.map(&:id)).to eq([1, 2])
    end
  end

  describe "has_many (ActiveRecord)" do
    it "works correctly" do
      player = Player.create!(name: "Hero", lv: 2)
      level = Level.find_by(:lv, 2)

      expect(level.players).to contain_exactly(player)
    end
  end
end
