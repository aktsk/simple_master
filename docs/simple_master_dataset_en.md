# SimpleMaster Dataset / Table (English)

> 日本語版: [simple_master_dataset_ja.md](simple_master_dataset_ja.md)

## Overview
In SimpleMaster, the dataset holds the actual data, and each master class maps to a table.
The loader reads external data, and the table keeps records and caches.

```
Dataset
  ├─ Table (Weapon)
  ├─ Table (Armor)
  └─ Table (Level)
```

## Dataset
### Role
- Load each `Table` via `loader`
- Keep `cache` for class/instance caches
- Provide diff overrides via `diff`

### Basic usage
```ruby
loader = SimpleMaster::Loader::QueryLoader.new
dataset = SimpleMaster::Storage::Dataset.new(loader: loader)
dataset.load

SimpleMaster.use_dataset(dataset) do
  # work with this dataset
end
```

### Main API
- `load` : load all target tables and update caches
- `reload` : reload or unload depending on table class
- `unload` : clear tables and cache
- `duplicate(diff: nil)` : duplicate a dataset (diff included)
- `table(klass)` : fetch table for a class

### diff
You can layer changes on top of loader data.
Set `dataset.diff` to a JSON/Hash and the diff is applied after load.
`Table.apply_diff` updates `id_hash` and overrides records.

```ruby
dataset = SimpleMaster::Storage::Dataset.new

dataset.diff = {
  "weapons" => {
    "1" => { "name" => "Updated Name" },
    "2" => nil
  }
}

dataset.load
```

### Dataset cache
Provides `cache_read` / `cache_fetch` / `cache_write` / `cache_delete`.
Use it for lightweight external caches. Data stays in memory, so mind the size.

## Table
### Role
- Hold record array (`all`)
- Build `id_hash` / `grouped_hash`
- Update class/instance caches
- Keep STI sub tables

### Main data
- `all` : array of records
- `id_hash` : `id` => record
- `grouped_hash` : `group_key` => grouped records
- `class_method_cache` : results of `cache_class_method`
- `method_cache` : results of `cache_method`

### STI and sub tables
When a class uses STI, `sub_table` returns a table per subclass.
`update_sub_tables` extracts subclasses from `all` and registers them.

## Table types
### Table (default)
- Loads all records when the dataset loads
- Builds `all` / `id_hash` / `grouped_hash` on load
- Records are frozen, so Copy-on-Write works well

### OndemandTable
- Builds `all` / `id_hash` / `grouped_hash` on first access
- Useful for large data or on-demand access

```ruby
dataset = SimpleMaster::Storage::Dataset.new(
  table_class: SimpleMaster::Storage::OndemandTable
)
```

### TestTable
- Lightweight table for tests
- Assumes `update` / `record_updated` diffs

```ruby
dataset = SimpleMaster::Storage::Dataset.new(
  table_class: SimpleMaster::Storage::TestTable
)
```

## Loader
A loader implements `read_raw` and `build_records`.
Besides `QueryLoader` and `MarshalLoader`, you can define your own.

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
