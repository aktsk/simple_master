# frozen_string_literal: true

FactoryBot.define do
  factory :player_item do
    association :player, strategy: :build
    item_type { "Weapon" }
    item_id { 1 }
    quantity { 1 }
  end
end
