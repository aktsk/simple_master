# SimpleMaster Columns (English)

## Overview
SimpleMaster columns are defined with `def_column`. At load time, type conversion,
cache helpers, and accessor methods are generated.
The behavior depends on `type` and DSL options.

```ruby
class Weapon < ApplicationMaster
  def_column :id
  def_column :name, type: :string
  def_column :attack, type: :float
  def_column :rarity

  enum :rarity, { common: 0, rare: 1, epic: 2 }
end
```

## Common options
### `type:`
- Example: `def_column :attack, type: :float`
- See the column type list below.

### `group_key:`
- Example: `def_column :lv, type: :integer, group_key: true`
- You can also use `group_key :lv`.

### `db_column_name:`
- Use when the DB column name differs.
- Example: `def_column :start_at, type: :time, db_column_name: :start_time`

### `globalize:`
- Adds locale-aware values using `I18n.locale`.
- Example: `def_column :name, globalize: true`
- You can also use `globalize :name`.
- Translation values live in `@_globalized_name` like `{ en: "Storm Edge", ja: "..." }`.
- Not supported on `id` / `enum` / `bitmask` / `sti` / `polymorphic_type`.
- Cannot be used with `group_key`.

## Column types

### id (IdColumn)
**Usage**
```ruby
def_column :id
```
**Behavior**
- Converts to `to_i` on assignment.
- In tests, updates `id_hash` when changed.

### integer
**Usage**
```ruby
def_column :lv, type: :integer
```
**Behavior**
- Converts to `to_i` on assignment (empty string becomes `nil`).

### float
**Usage**
```ruby
def_column :attack, type: :float
```
**Behavior**
- Converts to `to_f` on assignment (empty string becomes `nil`).

### string
**Usage**
```ruby
def_column :name, type: :string
```
**Behavior**
- Converts to `to_s` on assignment.
- Values are cached to reuse identical objects (`object_cache`).

### symbol
**Usage**
```ruby
def_column :kind, type: :symbol
```
**Behavior**
- Converts to `to_s` + `to_sym` on assignment.
- SQL/CSV output uses a string.

### boolean
**Usage**
```ruby
def_column :is_boss, type: :boolean
```
**Behavior**
- Integers use 0/1, strings accept "true" or "1".
- Adds a `name?` predicate.
- SQL/CSV output is 0/1.

### json
**Usage**
```ruby
def_column :info, type: :json
```
**Options**
- `symbolize_names: true` converts JSON keys to symbols.

**Behavior**
- Parses string values with `JSON.parse`.
- SQL/CSV output uses `JSON.generate`.
- Non-string assignments are not transformed by `symbolize_names`.

### time
**Usage**
```ruby
def_column :start_at, type: :time
```
**Options**
- `db_type: :time` outputs `HH:MM:SS` only.

**Behavior**
- Parses strings with `Date._parse` into `Time`.
- Sub-seconds are truncated.

### enum
**Usage**
```ruby
def_column :rarity, enum: { common: 0, rare: 1, epic: 2 }
# or
def_column :rarity
enum :rarity, { common: 0, rare: 1, epic: 2 }
```
**Options**
- `prefix`, `suffix` add a prefix/suffix to predicates.
  - `prefix: true` => `rarity_common?`
  - `suffix: :rarity` => `common_rarity?`

**Behavior**
- Values are stored as symbols.
- Adds `rarities` and `rarity_before_type_cast`.
- Predicate methods (e.g. `common?`) are generated.

### bitmask
**Usage**
```ruby
def_column :flags, type: :integer
bitmask :flags, as: [:tradeable, :soulbound, :limited]
```
**Behavior**
- Accepts array/symbol/integer and converts to bit integer.
- `flags` returns an array of symbols.
- Adds `flags_value` / `flags_value=` for raw integer bits.

### sti (STI type column)
**Usage**
```ruby
def_column :type, sti: true
```
**Behavior**
- Converts `type` to a string.
- Defines `sti_base_class` and `sti_column`.
- Loader should resolve classes by `type`.

### polymorphic_type
**Usage**
```ruby
def_column :reward_type, polymorphic_type: true
```
**Behavior**
- Used for `belongs_to polymorphic` type columns.
- Stores a class name string and sets `reward_type_class`.
- Empty strings become `nil`.

## Custom column types
Define custom columns by subclassing `SimpleMaster::Master::Column`.
If the class name ends with `Column`, the `type` is auto-registered.

```ruby
class MoneyColumn < SimpleMaster::Master::Column
  private

  def code_for_conversion
    <<-RUBY
      value = value&.to_i
    RUBY
  end

  def code_for_sql_value
    <<-RUBY
      #{name}
    RUBY
  end
end

class Product < ApplicationMaster
  def_column :price, type: :money
end
```

- Ensure the file is loaded before use.
- Override `init` if you need custom methods.
- See [lib/simple_master/master/column.rb](lib/simple_master/master/column.rb).
