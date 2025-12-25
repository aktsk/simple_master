# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Loader" do
  describe "loading" do
    it "instantiates STI records as subclasses" do
      pistol = Weapon.find(1)

      expect(pistol).to be_a(Gun)
      expect(pistol.attack).to eq(12.5)

      expect(Gun.all).to include(pistol)
      expect(Weapon.all).to include(pistol)

      expect(Blade.find_by_id(1)).to be_nil
      expect(Gun.find(1)).to eq(pistol)

      expect(Weapon.all.map(&:id)).to contain_exactly(1, 2, 3, 4)
      expect(Gun.all.map(&:id)).to contain_exactly(1, 3)
      expect(Blade.all.map(&:id)).to contain_exactly(2, 4)
    end
  end

  describe "Globalization" do
    let(:potion) { Potion.find(1) }
    let(:weapon) { Weapon.find(1) }

    it "can be loaded by loader" do
      I18n.with_locale(:ja) do
        expect(potion.name).to eq("マイナーヒール")
      end
    end

    it "applies globalize_proc when provided" do
      I18n.with_locale(:ja) do
        expect(weapon.name).to eq("ブロンズピストル")
      end
    end
  end

  it "applies diff json to dataset" do
    diff = {
      "weapons" => {
        "2" => { "attack" => 42.0, "_globalized_name" => { en: "Gold Saber", ja: "ゴールドセイバー" } },
        "3" => nil,
      },
    }

    dataset = $current_dataset.duplicate(diff: diff)
    dataset.load

    SimpleMaster.use_dataset(dataset) do
      weapon = Weapon.find(2)

      expect(weapon.attack).to eq(42.0)
      expect(weapon.name).to eq("Gold Saber")
      I18n.with_locale(:ja) do
        expect(weapon.name).to eq("ゴールドセイバー")
      end
      expect(Weapon.id_hash).not_to have_key(3)
    end
  end
end
