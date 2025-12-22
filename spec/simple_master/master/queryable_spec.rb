# frozen_string_literal: true

require "spec_helper"

RSpec.describe SimpleMaster::Master::Queryable do
  let(:connection) { ActiveRecord::Base.connection }

  before do
    %w(weapons levels).each do |table|
      connection.execute("DELETE FROM #{table}")
    end
  end

  describe ".table_available?" do
    it "returns true for existing tables" do
      expect(Weapon.table_available?).to be(true)
    end

    it "returns false for missing tables" do
      allow(Weapon).to receive(:table_name).and_return("missing_table")

      expect(Weapon.table_available?).to be(false)
    end
  end

  describe ".query_select_all" do
    it "returns rows from the backing table" do
      connection.execute <<~SQL
        INSERT INTO weapons (id, type, name, attack, rarity, flags)
        VALUES (1, 'Gun', 'Queryable Sword', 9.5, 2, 1)
      SQL

      result = Weapon.query_select_all
      row = result.to_a.find { |record| record["id"] == 1 }

      expect(result.columns).to include("name", "attack")
      expect(row["name"]).to eq("Queryable Sword")
      expect(row["attack"]).to eq(9.5)
    end
  end

  describe ".sqlite_insert_query" do
    it "builds SQL that can be executed" do
      weapon = Weapon.new(
        id: 1,
        type: "Gun",
        name: "SQL Pistol",
        attack: 11.0,
        info: { slots: 1 },
        metadata: { "source" => "sql" },
        rarity: :rare,
        flags: [:tradeable],
      )

      sql = Weapon.sqlite_insert_query([weapon])
      connection.execute(sql)

      row = connection.select_all("SELECT name, rarity, flags FROM weapons WHERE id = 1").to_a.first
      expect(row["name"]).to eq("SQL Pistol")
      expect(row["rarity"].to_i).to eq(1)
      expect(row["flags"].to_i).to eq(1)
    end
  end

  describe ".query_delete_all" do
    it "removes all rows from the table" do
      connection.execute("INSERT INTO levels (id, lv, attack) VALUES (1, 3, 2.5)")

      expect(connection.select_all("SELECT * FROM levels").to_a.size).to eq(1)

      Level.query_delete_all

      expect(connection.select_all("SELECT * FROM levels").to_a).to be_empty
    end
  end
end
