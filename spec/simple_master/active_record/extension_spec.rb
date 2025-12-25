# frozen_string_literal: true

require "spec_helper"

RSpec.describe SimpleMaster::ActiveRecord::Extension do
  before do
    reset_active_record_tables
  end

  it "connects ActiveRecord to master" do
    player = Player.create!(name: "Hero", lv: 2)
    level = Level.find_by(:lv, 2)

    expect(player.level).to eq(level)
  end

  it "resolves polymorphic belongs_to for master records" do
    player = Player.create!(name: "Hero", lv: 1)
    player_item1 = PlayerItem.create!(player: player, item_type: "Weapon", item_id: 1)

    expect(player_item1.item).to be_a(Weapon)
    expect(player_item1.item.name).to eq("Bronze Pistol")

    player_item2 = PlayerItem.create!(player: player, item: Weapon.find(1))

    expect(player_item2.item_id).to eq(1)
    expect(player_item2.item_type).to eq("Gun")
  end

  it "aggregates items through player_items" do
    player = Player.create!(name: "Hero", lv: 1)
    PlayerItem.create!(player: player, item_type: "Weapon", item_id: 1, quantity: 1)
    PlayerItem.create!(player: player, item_type: "Armor", item_id: 2, quantity: 1)
    PlayerItem.create!(player: player, item_type: "Potion", item_id: 3, quantity: 1)

    expect(player.items.map(&:class)).to contain_exactly(Gun, Armor, Potion)
    expect(player.items.map { |item| item.class.base_class }).to contain_exactly(Weapon, Armor, Potion)
    expect(player.items.map(&:name)).to contain_exactly("Bronze Pistol", "Chain Mail", "Elixir")
  end
end
