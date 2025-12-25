# frozen_string_literal: true

rails_versions = ENV.fetch("RAILS_VERSIONS", "7.0 7.1 7.2 8.0 8.1").split

rails_versions.each do |version|
  appraise "rails-#{version.tr('.', '_')}" do
    gem "rails", "~> #{version}"
    gem "sqlite3", "~> 2.1"
    gem "rspec"
    gem "factory_bot"
    gem "puma"
  end
end
