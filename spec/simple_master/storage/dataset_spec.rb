# frozen_string_literal: true

require "spec_helper"

RSpec.describe SimpleMaster::Storage::Dataset do
  it "keeps loaded records when digest is unchanged" do
    weapon = Weapon.first
    $current_dataset.load

    expect(Weapon.first.object_id).to equal(weapon.object_id)
  end

  it "duplicates dataset without reloading tables" do
    dup_dataset = $current_dataset.duplicate
    dup_dataset.load

    expect(SimpleMaster.use_dataset(dup_dataset) { Weapon.first.object_id }).to equal(Weapon.first.object_id)
  end

  it "memoizes dataset cache_fetch" do
    dataset = described_class.new(loader: JsonLoader.new)

    first_time = dataset.cache_fetch(:foo) { Object.new }
    second_time = dataset.cache_fetch(:foo) { Object.new }

    expect(first_time.object_id).to eq(second_time.object_id)
  end
end
