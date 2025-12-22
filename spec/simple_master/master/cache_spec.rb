# frozen_string_literal: true

require "spec_helper"

RSpec.describe "cache" do
  describe "cache_class_method" do
    subject(:cached_result) { Weapon.receivable_sources }

    let!(:result) { Weapon.receivable_sources }
    let(:enemies) { Enemy.id_hash }

    it "collects receivable sources per item" do
      expect(cached_result).to match({
                                       1 => contain_exactly(enemies[1]),
                                       2 => contain_exactly(enemies[4]),
                                       3 => contain_exactly(enemies[2], enemies[9], enemies[10]),
                                     })
      expect(cached_result.object_id).to be(result.object_id)
    end

    it "keeps STI sub-table caches separate" do
      expect(Blade.receivable_sources.keys).to contain_exactly(2)
      expect(Gun.receivable_sources.keys).to contain_exactly(1, 3)
    end
  end

  describe "cache_method" do
    subject(:cached_result) { weapon.receivable_sources }

    let(:weapon) { Weapon.find(1) }
    let!(:result) { weapon.receivable_sources }

    it "collects receivable sources per item" do
      expect(cached_result.map(&:id)).to contain_exactly(1)
      expect(cached_result.object_id).to be(result.object_id)
    end
  end
end
