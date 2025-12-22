# frozen_string_literal: true

FactoryBot.define do
  factory :player do
    name { "Factory Player" }
    lv { 1 }
    association :level, strategy: :build

    after(:build) do |player, evaluator|
      player.level = build(:level, lv: evaluator.lv)
    end
  end
end
