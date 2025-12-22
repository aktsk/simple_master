# frozen_string_literal: true

require "spec_helper"

RSpec.describe "model" do
  describe "sti_class?" do
    it "returns true for STI base classes and subclasses" do
      expect(Weapon.sti_class?).to be(true)
      expect(Gun.sti_class?).to be(true)
      expect(Armor.sti_class?).to be(false)
    end
  end

  describe "sti_base_class?" do
    it "returns true only for STI base classes" do
      expect(Weapon.sti_base_class?).to be(true)
      expect(Gun.sti_base_class?).to be(false)
      expect(Armor.sti_base_class?).to be(false)
    end
  end

  describe "sti_sub_class?" do
    it "returns true only for STI subclasses" do
      expect(Gun.sti_sub_class?).to be(true)
      expect(Blade.sti_sub_class?).to be(true)
      expect(Weapon.sti_sub_class?).to be(false)
      expect(Armor.sti_sub_class?).to be(false)
    end
  end

  describe "base_class" do
    it "returns the STI base class when present" do
      expect(Weapon.base_class).to eq(Weapon)
      expect(Gun.base_class).to eq(Weapon)
      expect(Blade.base_class).to eq(Weapon)
      expect(Armor.base_class).to eq(Armor)
    end
  end

  describe "base_class?" do
    it "returns true for STI base classes and non-STI classes" do
      expect(Weapon.base_class?).to be(true)
      expect(Gun.base_class?).to be(false)
      expect(Armor.base_class?).to be(true)
    end
  end

  describe "globalized?" do
    it "returns true when any column is globalized" do
      expect(Weapon.globalized?).to be(true)
    end

    it "returns false when no globalized columns exist" do
      expect(Armor.globalized?).to be(false)
    end
  end
end
