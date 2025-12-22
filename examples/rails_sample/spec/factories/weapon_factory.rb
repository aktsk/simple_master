# frozen_string_literal: true

FactoryBot.define do
  factory :weapon do
    type { "Gun" }
    icon { "fa-solid fa-gun" }
    name { "Factory Weapon" }
    attack { 10.0 }
    info { { slots: 1, origin: "factory" } }
    metadata { { "source" => "factory", "tags" => ["default"] } }
    rarity { :common }
    flags { [:tradeable] }
  end
end
