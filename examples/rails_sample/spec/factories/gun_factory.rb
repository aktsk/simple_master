# frozen_string_literal: true

FactoryBot.define do
  factory :gun, class: "Gun" do
    name { "Factory Gun" }
    attack { 12.0 }
    info { { slots: 2, origin: "factory" } }
    metadata { { "source" => "factory", "tags" => ["gun"] } }
    rarity { :rare }
    flags { [:tradeable, :limited] }
  end
end
