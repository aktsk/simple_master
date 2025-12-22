# frozen_string_literal: true

require "spec_helper"

RSpec.describe SimpleMaster::Loader::QueryLoader do
  it "loads records from database tables" do
    connection = ActiveRecord::Base.connection

    %w(weapons armors potions levels enemies rewards).each do |table|
      connection.execute("DELETE FROM #{table}")
    end

    info_json = connection.quote('{"slots":1,"origin":"db"}')
    metadata_json = connection.quote('{"source":"query","tags":["loader"]}')

    connection.execute <<~SQL
      INSERT INTO weapons (id, type, name, attack, info, metadata, rarity, flags)
      VALUES (1, 'Gun', 'Query Pistol', 12.5, #{info_json}, #{metadata_json}, 1, 5)
    SQL

    connection.execute <<~SQL
      INSERT INTO enemies (id, name, is_boss, start_at, end_at, attack, defence, hp)
      VALUES (1, 'DB Ogre', 1, '2024-05-01 10:00:00', '2024-05-01 18:00:00', 14.0, 8.0, 45.0)
    SQL

    dataset = SimpleMaster::Storage::Dataset.new(loader: described_class.new)
    dataset.load

    SimpleMaster.use_dataset(dataset) do
      weapon = Weapon.find(1)

      expect(weapon).to be_a(Gun)
      expect(weapon.name).to eq("Query Pistol")
      expect(weapon.attack).to eq(12.5)
      expect(weapon.rarity).to eq(:rare)
      expect(weapon.flags).to eq([:tradeable, :limited])
      expect(weapon.info).to(satisfy { |value|
        [{ slots: 1, origin: "db" }, { "slots" => 1, "origin" => "db" }].include?(value)
      })
      expect(weapon.metadata).to eq({ "source" => "query", "tags" => ["loader"] })

      enemy = Enemy.find(1)
      expect(enemy.is_boss).to be(true)
      expect(enemy.start_at).to eq(Time.utc(2024, 5, 1, 10, 0, 0))
      expect(enemy.end_at).to eq(Time.utc(2024, 5, 1, 18, 0, 0))
    end
  end
end
