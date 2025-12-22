# frozen_string_literal: true

FactoryBot.define do
  factory :armor do
    icon { "fa-solid fa-shield" }
    name { "Factory Armor" }
    defence { 8.0 }
  end
end
