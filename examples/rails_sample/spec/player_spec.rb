# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe Player do
  before do
    PlayerItem.delete_all
    described_class.delete_all
  end

  describe "creation" do
    context "when creating a player" do
      let!(:level1) do
        create(:level, lv: 1, attack: 5.0, defence: 2.0, hp: 18.0, next_exp: 10, hp_recovery_sec: 60, stamina: 5, stamina_recovery_sec: 30)
      end
      let!(:player) { described_class.create!(name: "Nova", lv: level1.lv) }

      it "creates a player with the matching level" do
        expect(player).to be_a(described_class)
        expect(player.level).to be_a(Level)
        expect(player.exp).to eq(0)
      end
    end
  end

  describe "#challenge_enemy" do
    context "when the player wins" do
      let!(:now) { Time.current }
      let!(:battle_enemy) do
        create(:enemy, name: "Clockwork Rat", start_at: now - 1.hour, end_at: now + 1.hour, attack: 7.0, defence: 3.0, hp: 10.0, exp: 12, stamina_cost: 4)
      end
      let!(:battle_level_one) do
        create(:level, lv: 1, attack: 8.0, defence: 2.0, hp: 20.0, next_exp: 10, hp_recovery_sec: 60, stamina: 6, stamina_recovery_sec: 30)
      end
      let!(:battle_level_two) do
        create(:level, lv: 2, attack: 12.0, defence: 4.0, hp: 26.0, next_exp: 20, hp_recovery_sec: 50, stamina: 8, stamina_recovery_sec: 25)
      end
      let!(:battle_reward) { create(:weapon, name: "Victory Blade") }
      let!(:battle_reward_entry) do
        create(:reward, enemy_id: battle_enemy.id, reward_type: "Weapon", reward_id: battle_reward.id)
      end
      let!(:battle_player) { described_class.create!(name: "Raider", lv: 1) }
      let!(:existing_item) do
        create(:player_item, player: battle_player, item_type: "Weapon", item_id: battle_reward.id, quantity: 1)
      end

      it "levels up and receives rewards after a win" do
        result = battle_player.challenge_enemy(battle_enemy, at: now)

        expect(result[:ok]).to be(true)
        expect(battle_player.reload.lv).to eq(2)
        expect(battle_player.exp).to eq(2)
        expect(battle_player.hp).to be_within(0.01).of(13.1373)
        expect(battle_player.stamina).to eq(8)
        expect(battle_player.items.map(&:id)).to include(battle_reward.id)
        expect(battle_player.player_items.find_by(item_type: "Weapon", item_id: battle_reward.id).quantity).to eq(1)
      end
    end

    context "when the player loses" do
      let!(:now) { Time.current }
      let!(:battle_enemy) do
        create(:enemy, name: "Stone Golem", start_at: now - 1.hour, end_at: now + 1.hour, attack: 5.0, defence: 50.0, hp: 30.0, exp: 1, stamina_cost: 1)
      end
      let!(:battle_level_one) do
        create(:level, lv: 1, attack: 3.0, defence: 1.0, hp: 12.0, next_exp: 10, hp_recovery_sec: 60, stamina: 4, stamina_recovery_sec: 30)
      end
      let!(:battle_player) { described_class.create!(name: "Hero", lv: 1) }

      it "fails with an attack_too_low reason" do
        result = battle_player.challenge_enemy(battle_enemy, at: now)

        expect(result[:ok]).to be(false)
        expect(result[:reason]).to eq(:attack_too_low)
        expect(battle_player.reload.lv).to eq(1)
      end
    end
  end

  describe "#use_potion" do
    context "when a potion is used" do
      let!(:now) { Time.current }
      let!(:potion_level) do
        create(:level, lv: 1, attack: 5.0, defence: 2.0, hp: 18.0, next_exp: 10, hp_recovery_sec: 60, stamina: 5, stamina_recovery_sec: 30)
      end
      let!(:potion) { create(:potion, hp: 8.0) }
      let!(:healing_player) { described_class.create!(name: "Cleric", lv: 1, hp: 6.0, hp_updated_at: now) }
      let!(:potion_item) { create(:player_item, player: healing_player, item_type: "Potion", item_id: potion.id, quantity: 1) }

      it "heals instantly with a potion" do
        expect(healing_player.use_potion(potion, at: now)).to be(true)
        expect(healing_player.reload.hp).to eq(14.0)
        expect(healing_player.player_items.where(item_type: "Potion", item_id: potion.id)).to be_empty
      end
    end
  end

  describe "equipment" do
    context "when equipping a weapon" do
      let!(:level1) do
        create(:level, lv: 1, attack: 5.0, defence: 2.0, hp: 18.0, next_exp: 10, hp_recovery_sec: 60, stamina: 5, stamina_recovery_sec: 30)
      end
      let!(:weapon) { create(:weapon, name: "Starter Gun") }
      let!(:player) { described_class.create!(name: "Hero", lv: 1) }
      let!(:player_item) { create(:player_item, player: player, item_type: "Weapon", item_id: weapon.id, quantity: 1) }

      it "equips the weapon" do
        expect(player.equip_weapon(weapon)).to be(true)
        expect(player.reload.weapon_id).to eq(weapon.id)
      end
    end

    context "when equipping armor without owning it" do
      let!(:level1) do
        create(:level, lv: 1, attack: 5.0, defence: 2.0, hp: 18.0, next_exp: 10, hp_recovery_sec: 60, stamina: 5, stamina_recovery_sec: 30)
      end
      let!(:armor) { create(:armor, name: "Starter Armor") }
      let!(:player) { described_class.create!(name: "Hero", lv: 1) }

      it "rejects equipping armor" do
        expect(player.equip_armor(armor)).to be(false)
        expect(player.reload.armor_id).to be_nil
      end
    end
  end
end
