# frozen_string_literal: true

require "spec_helper"

RSpec.describe SimpleMaster::Master::Filterable do
  it "supports id-based find helpers" do
    expect(Weapon.find(1).name).to eq("Bronze Pistol")
    expect(Weapon.find_by_id(99)).to be_nil
    expect(Weapon.find_by_ids([1, 3]).map(&:id)).to eq([1, 3])
    expect { Weapon.find_by_ids!([1, 99]) }.to raise_error(KeyError)
  end

  it "supports grouped lookups" do
    expect(Reward.find_by(:enemy_id, 1).id).to eq(1)
    expect(Reward.all_by(:enemy_id, 1).map(&:id)).to eq([1, 2])
    expect { Reward.all_by!(:enemy_id, 99) }.to raise_error(KeyError)
    expect(Reward.all_in(:enemy_id, [1, 2]).map(&:id)).to eq([1, 2, 3, 4])
    expect(Reward.all_in(:enemy_id, [1, 2])).to be_frozen
  end

  it "delegates collection helpers to all" do
    expect(Weapon.pluck(:name)).to include("Bronze Pistol", "Silver Saber", "Crimson Rifle")
    expect(Weapon.first).to be_a(Weapon)
  end

  it "checks id existence" do
    expect(Weapon.exists?(1)).to be(true)
    expect(Weapon.exists?(99)).to be(false)
  end

  it "raises on missing group key and handles empty all_in" do
    expect { Reward.all_by(:unknown_key, 1) }.to raise_error(KeyError)
    expect(Reward.all_in(:enemy_id, [])).to eq([])
    expect(Reward.all_in(:enemy_id, [])).to be_frozen
  end
end
