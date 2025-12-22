# Rails Sample App

This sample app demonstrates SimpleMaster in a compact, game-like domain.
It is used to exercise column casting and association patterns (STI, polymorphic
`belongs_to`, `has_many`).

## Development Setup
```bash
bundle install
cd examples/rails_sample
bundle exec rails db:prepare
bundle exec rails s
```

## Database Configuration
Database settings live in `examples/rails_sample/config/database.yml`.

- `development`: sqlite3 at `examples/rails_sample/db/development.sqlite3`
- `test`: sqlite3 in-memory (`:memory:`)
- `production`: sqlite3 at `examples/rails_sample/db/production.sqlite3`

If you need a different DB, edit `config/database.yml` or set `DATABASE_URL`.

## Domain Model
```
SimpleMaster (masters)                   ActiveRecord

[Weapon] (STI: Gun, Blade)               [Player] --< player_items >-- (polymorphic to Weapon/Armor/Potion)
[Armor]                                  PlayerItem: belongs_to :item, polymorphic
[Potion]
[Level] --< players (lv) >-- [Player]
[Enemy] --< rewards >-- [Reward] (reward_type/reward_id -> Weapon/Armor/Potion)
```

## Masters
- **Weapon** (`Gun`, `Blade`)
  - `id`
  - `type`
  - `name`
  - `attack` (float)
  - `info` (json, symbolize_names: true)
  - `metadata` (json, symbolize_names: false)
  - `rarity` (enum)
  - `flags` (bitmask)
  - Notes: polymorphic target (PlayerItem, Reward)
- **Armor**
  - `id`
  - `name`
  - `defence` (float)
  - Notes: polymorphic target
- **Potion**
  - `id`
  - `name`
  - `hp` (float)
  - Notes: polymorphic target
- **Level**
  - `id`
  - `lv` (unique)
  - `attack` (float)
  - `defence` (float)
  - `hp` (float)
  - Associations: `has_many :players` (lv)
- **Enemy**
  - `id`
  - `name`
  - `is_boss` (boolean)
  - `start_at` (time)
  - `end_at` (time)
  - `attack`
  - `defence`
  - `hp`
  - Associations: `has_many :rewards`
- **Reward**
  - `id`
  - `enemy_id`
  - `reward_type`
  - `reward_id`
  - Associations: `belongs_to :enemy`; polymorphic `belongs_to` Weapon/Armor/Potion

## ActiveRecord
- **Player**
  - `id`
  - `name`
  - `lv`
  - Associations: `belongs_to :level` (lv); `has_many :player_items`; `has_many :items, through: :player_items`
- **PlayerItem**
  - `player_id`
  - `item_type`
  - `item_id`
  - Associations: `belongs_to :player`; polymorphic `belongs_to :item`

## Fixtures
Fixtures live in `examples/rails_sample/fixtures/masters`.

- `weapons.json` (STI Gun/Blade), `armors.json`, `potions.json`, `levels.json` (uses `lv` as unique key),
  `enemies.json`, `rewards.json`
- Aim to include representative casts (float/json/globalize where useful) and polymorphic/has_many links.

## Related Specs
- `simple_master/active_record/extension_spec.rb`: AR↔master (`belongs_to_master`)
- `simple_master/master/item_spec.rb`: column casting and master associations
- `simple_master/master/filterable_spec.rb`: find/find_by/all_by/all_in
- `simple_master/master/cache_spec.rb`: cache_method, cache_class_method
- `simple_master/storage/loader_spec.rb`: STI instantiation, diff application
- `simple_master/loader/marshal_loader_spec.rb`: Marshal dump/load roundtrip
- `simple_master/storage/dataset_spec.rb`: dataset cache/diff duplication
