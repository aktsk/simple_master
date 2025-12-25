# frozen_string_literal: true

FactoryBot.define do
  factory :enemy do
    name { "Factory Enemy" }
    is_boss { false }
    start_at { Time.utc(2024, 5, 1, 10, 0, 0) }
    end_at { Time.utc(2024, 5, 1, 18, 0, 0) }
    attack { 6.0 }
    defence { 3.0 }
    hp { 18.0 }
    exp { 8 }
    stamina_cost { 2 }
  end
end
