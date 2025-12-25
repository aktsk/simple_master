# frozen_string_literal: true

Rails.application.routes.draw do
  root "game#show"
  post "/play", to: "game#play"
end
