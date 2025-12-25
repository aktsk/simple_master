# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe Enemy do
  describe "availability" do
    let!(:now) { Time.current }
    let(:within_window) { now }
    let(:before_window) { now - 2.hours }
    let(:after_window) { now + 2.hours }
    let!(:bounded_enemy) do
      create(:enemy, name: "Bounded Enemy", start_at: now - 1.hour, end_at: now + 1.hour)
    end
    let!(:timeless_enemy) do
      create(:enemy, name: "Unbounded Enemy", start_at: nil, end_at: nil)
    end

    it "checks availability per enemy" do
      expect(bounded_enemy.available?(within_window)).to be(true)
      expect(bounded_enemy.available?(before_window)).to be(false)
      expect(bounded_enemy.available?(after_window)).to be(false)
      expect(timeless_enemy.available?(within_window)).to be(true)
      expect(timeless_enemy.available?(before_window)).to be(true)
      expect(timeless_enemy.available?(after_window)).to be(true)
    end

    it "filters enemies available at the time" do
      enemies = described_class.available_at(within_window)

      expect(enemies).to include(bounded_enemy, timeless_enemy)

      earlier_enemies = described_class.available_at(before_window)

      expect(earlier_enemies).to include(timeless_enemy)
      expect(earlier_enemies).not_to include(bounded_enemy)

      later_enemies = described_class.available_at(after_window)

      expect(later_enemies).to include(timeless_enemy)
      expect(later_enemies).not_to include(bounded_enemy)
    end
  end
end
