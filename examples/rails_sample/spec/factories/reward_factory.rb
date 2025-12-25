# frozen_string_literal: true

FactoryBot.define do
  factory :reward do
    enemy_id { 1 }
    association :enemy, strategy: :build
    association :reward, factory: :weapon, strategy: :build
  end
end
