# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :weapons, force: true do |t|
    t.string :type
    t.string :icon
    t.string :name
    t.float :attack
    t.json :info
    t.json :metadata
    t.integer :rarity
    t.integer :flags
  end

  create_table :armors, force: true do |t|
    t.string :icon
    t.string :name
    t.float :defence
  end

  create_table :potions, force: true do |t|
    t.string :name
    t.float :hp
  end

  create_table :levels, force: true do |t|
    t.integer :lv
    t.float :attack
    t.float :defence
    t.float :hp
    t.integer :next_exp
    t.integer :hp_recovery_sec
    t.integer :stamina
    t.integer :stamina_recovery_sec
  end

  create_table :enemies, force: true do |t|
    t.string :name
    t.boolean :is_boss
    t.datetime :start_at
    t.datetime :end_at
    t.float :attack
    t.float :defence
    t.float :hp
    t.integer :exp
    t.integer :stamina_cost
  end

  create_table :rewards, force: true do |t|
    t.integer :enemy_id
    t.string :reward_type
    t.integer :reward_id
  end

  create_table :players, force: true do |t|
    t.string :name, null: false
    t.integer :lv, null: false
    t.integer :exp, null: false, default: 0
    t.integer :weapon_id
    t.integer :armor_id
    t.float :hp
    t.datetime :hp_updated_at
    t.integer :stamina
    t.datetime :stamina_updated_at
  end

  create_table :player_items, force: true do |t|
    t.integer :player_id, null: false
    t.string :item_type, null: false
    t.integer :item_id, null: false
    t.integer :quantity, null: false, default: 0
  end
end
