# frozen_string_literal: true

require "spec_helper"

RSpec.describe "columns" do
  before { reset_active_record_tables }

  describe "IntegerColumn" do
    it "casts correctly" do
      level = Level.new

      level.lv = "3"
      expect(level.lv).to eq(3)
      expect(level.lv_value_for_sql).to eq(3)

      level.lv = "  "
      expect(level.lv).to be_nil
      expect(level.lv_value_for_sql).to eq("NULL")

      level.lv = 4
      expect(level.lv).to eq(4)
      expect(level.lv_value_for_sql).to eq(4)
    end
  end

  describe "FloatColumn" do
    it "casts correctly" do
      weapon = Weapon.new

      weapon.attack = "12.5"
      expect(weapon.attack).to eq(12.5)
      expect(weapon.attack_value_for_sql).to eq(12.5)

      weapon.attack = 7
      expect(weapon.attack).to eq(7.0)
      expect(weapon.attack_value_for_sql).to eq(7.0)

      weapon.attack = " "
      expect(weapon.attack).to be_nil
      expect(weapon.attack_value_for_sql).to eq("NULL")
    end
  end

  describe "BooleanColumn" do
    it "casts correctly" do
      enemy = Enemy.new

      enemy.is_boss = "true"
      expect(enemy.is_boss).to be(true)
      expect(enemy.is_boss?).to be(true)
      expect(enemy.is_boss_value_for_sql).to eq(1)

      enemy.is_boss = "0"
      expect(enemy.is_boss).to be(false)
      expect(enemy.is_boss?).to be(false)
      expect(enemy.is_boss_value_for_sql).to eq(0)

      enemy.is_boss = nil
      expect(enemy.is_boss).to be_nil
      expect(enemy.is_boss?).to be(false)
      expect(enemy.is_boss_value_for_sql).to eq("NULL")
    end
  end

  describe "TimeColumn" do
    it "casts correctly" do
      enemy = Enemy.new

      enemy.start_at = "2024-05-01T10:00:00Z"
      expect(enemy.start_at).to eq(Time.utc(2024, 5, 1, 10, 0, 0))
      expect(enemy.start_at_value_for_sql).to eq("'2024-05-01 10:00:00'")

      time_value = Time.utc(2024, 5, 2, 12, 30, 15)
      enemy.end_at = time_value
      expect(enemy.end_at).to eq(time_value)

      enemy.start_at = nil
      expect(enemy.start_at_value_for_sql).to eq("NULL")
    end
  end

  describe "JsonColumn" do
    it "(with symbolize_names: true) casts correctly" do
      weapon = Weapon.new

      weapon.info = { slots: 2, origin: "ruins" }
      expect(weapon.info).to eq({ slots: 2, origin: "ruins" })
      expect(weapon.info_value_for_sql).to eq("'{\"slots\":2,\"origin\":\"ruins\"}'")

      weapon.info = "{\"slots\":1,\"origin\":\"forge\"}"
      expect(weapon.info).to eq({ slots: 1, origin: "forge" })
      expect(weapon.info_value_for_sql).to eq("'{\"slots\":1,\"origin\":\"forge\"}'")

      weapon.info = "null"
      expect(weapon.info).to be_nil
      expect(weapon.info_value_for_sql).to eq("NULL")
    end

    it "(with symbolize_names: false) casts correctly" do
      weapon = Weapon.new

      weapon.metadata = "{\"source\":\"archive\",\"tags\":[\"starter\"]}"
      expect(weapon.metadata).to eq({ "source" => "archive", "tags" => ["starter"] })
      expect(weapon.metadata_value_for_sql).to eq("'{\"source\":\"archive\",\"tags\":[\"starter\"]}'")

      weapon.metadata = { "source" => "manual", "tags" => ["custom"] }
      expect(weapon.metadata).to eq({ "source" => "manual", "tags" => ["custom"] })
      expect(weapon.metadata_value_for_sql).to eq("'{\"source\":\"manual\",\"tags\":[\"custom\"]}'")

      weapon.metadata = "null"
      expect(weapon.metadata).to be_nil
      expect(weapon.metadata_value_for_sql).to eq("NULL")
    end
  end

  describe "EnumColumn" do
    it "casts correctly" do
      weapon = Weapon.new

      weapon.rarity = "1"
      expect(weapon.rarity).to eq(:rare)
      expect(weapon.rarity_value_for_sql).to eq(1)

      weapon.rarity = 2
      expect(weapon.rarity).to eq(:epic)
      expect(weapon.rarity_value_for_sql).to eq(2)

      weapon.rarity = nil
      expect(weapon.rarity_value_for_sql).to eq("NULL")
    end
  end

  describe "BitmaskColumn" do
    it "casts correctly" do
      weapon = Weapon.new

      weapon.flags = [:tradeable, :limited]
      expect(weapon.flags).to eq([:tradeable, :limited])
      expect(weapon.flags_value_for_sql).to eq(5)

      weapon.flags = :soulbound
      expect(weapon.flags).to eq([:soulbound])

      weapon.flags = nil
      expect(weapon.flags_value_for_sql).to eq("NULL")
    end
  end

  describe "PolymorphicTypeColumn" do
    it "casts correctly" do
      reward = Reward.new

      reward.reward_type = :Potion
      expect(reward.reward_type).to eq("Potion")
      expect(reward.reward_type_class).to eq(Potion)
      expect(reward.reward_type_value_for_sql).to eq("'Potion'")

      reward = Reward.find(3)
      expect(reward.reward_type_class).to eq(Potion)
      expect(reward.reward).to eq(Potion.find(2))
    end
  end

  describe "StiTypeColumn" do
    it "casts correctly" do
      weapon = Gun.new

      expect(weapon.type).to eq("Gun")
      expect(weapon.type_value_for_sql).to eq("'Gun'")
    end
  end
end
