# SimpleMaster Getting Started Guide

## Purpose
- Handle master data fast without relying on Rails/ActiveRecord
- Reference records as Ruby objects and define associations and caches
- Use without a DB and switch datasets by use case

## Installation
Add to Gemfile and bundle.

```ruby
gem "simple_master"
```

```bash
bundle install
```

## Initialization
Initialize SimpleMaster at boot and load a dataset.

```ruby
# config/initializers/simple_master.rb
Rails.application.config.after_initialize do
  Rails.application.eager_load!

  SimpleMaster.init(for_test: Rails.env.test?)

  loader = SimpleMaster::Loader::QueryLoader.new
  $current_dataset = SimpleMaster::Storage::Dataset.new(loader: loader)
  $current_dataset.load
end
```

If you load JSON fixtures, use the `JsonLoader` described below.

## Defining Master Classes
Create masters based on `ApplicationMaster`.

```ruby
# app/models/application_master.rb
class ApplicationMaster < SimpleMaster::Master
  self.abstract_class = true
end
```

```ruby
# app/models/weapon.rb
class Weapon < ApplicationMaster
  def_column :id
  def_column :type, sti: true
  def_column :name
  def_column :attack, type: :float
  def_column :rarity, type: :integer

  enum :rarity, { common: 0, rare: 1, epic: 2 }
  bitmask :flags, as: [:tradeable, :soulbound, :limited]

  validates :name, presence: true
  validates :attack, numericality: { greater_than_or_equal_to: 0 }
end
```

## Data Loading (DB / Fixture)
### Load from DB
Use the default `QueryLoader` to load from DB tables.

```ruby
loader = SimpleMaster::Loader::QueryLoader.new
$current_dataset = SimpleMaster::Storage::Dataset.new(loader: loader)
$current_dataset.load
```

### Build a Loader (JSON fixtures)
Example: implement a loader to read JSON.

```ruby
class JsonLoader < SimpleMaster::Loader
  FIXTURE_DIR = Rails.root.join("fixtures/masters")

  def read_raw(table)
    File.read(FIXTURE_DIR.join("#{table.klass.table_name}.json"))
  end

  def build_records(klass, raw)
    JSON.parse(raw).map { |attrs| klass.new(attrs) }
  end
end
```

If you use STI, add a branch that resolves the class from `type`
(see [dummy/lib/json_loader.rb](dummy/lib/json_loader.rb)).

```ruby
loader = JsonLoader.new
$current_dataset = SimpleMaster::Storage::Dataset.new(loader: loader)
$current_dataset.load
```

## ActiveRecord Integration
Use the Extension to reference masters from ActiveRecord models.

```ruby
# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  include SimpleMaster::ActiveRecord::Extension
end
```

```ruby
class Player < ApplicationRecord
  belongs_to :level, foreign_key: :lv, primary_key: :lv
  has_many :player_items
end
```

## Test Setup
Create a dataset per example to reset state.
In tests, `SimpleMaster::Master::Editable` and `TestTable` are useful.
Example with RSpec:

```ruby
ApplicationMaster.prepend(SimpleMaster::Master::Editable)

RSpec.configure do |config|
  config.around do |example|
    dataset = SimpleMaster::Storage::Dataset.new(table_class: SimpleMaster::Storage::TestTable)
    SimpleMaster.use_dataset(dataset) { example.run }
  end
end
```

## Useful Methods
- `SimpleMaster.use_dataset(dataset) { ... }` : temporarily switch dataset
- `cache_method` / `cache_class_method` : define fast caches
- `enum` / `bitmask` / `globalize` : column extensions

## Notes
- Do not use `SimpleMaster::Master::Editable` in production; it is for tests
- Swap the `Loader` based on your data source
