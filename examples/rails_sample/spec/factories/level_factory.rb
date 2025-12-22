# frozen_string_literal: true

FactoryBot.define do
  factory :level do
    lv { 1 }
    attack { 2.0 }
    defence { 1.0 }
    hp { 10.0 }
    next_exp { 10 }
    hp_recovery_sec { 60 }
    stamina { 10 }
    stamina_recovery_sec { 30 }
  end
end
