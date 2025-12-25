# SimpleMaster Associations (English)

> 日本語版: [simple_master_associations_ja.md](simple_master_associations_ja.md)

## Overview
SimpleMaster provides `belongs_to`, `has_one`, `has_many`, and `has_many :through`.

## Definitions
```ruby
class Player < ApplicationRecord
  belongs_to :level, foreign_key: :lv, primary_key: :lv
  has_many :player_items
end
```

```ruby
class Reward < ApplicationMaster
  belongs_to :enemy
  belongs_to :reward, polymorphic: true
end
```

The lookup path depends on whether the target is `SimpleMaster::Master`
or `ActiveRecord::Base`.

- Master to Master: use `all_by` / `find_by`
  - These are fast, so values are fetched on each call. Cache in a variable if used often.
- ActiveRecord: use `simple_master_connection`
  - `belongs_to_store` / `has_many_store` (RequestStore) caches per request.

## Common options
### `class_name:`
- Example: `belongs_to :reward, class_name: "Weapon"`
- Explicitly sets the target class.

### `foreign_key:`
- Example: `has_many :players, foreign_key: :lv`
- Sets the foreign key column.

### `primary_key:`
- Example: `belongs_to :level, primary_key: :lv`
- Sets the target primary key (default is `:id`).

## Association types
- `belongs_to` : `belongs_to :enemy`
- `belongs_to (polymorphic)` : `belongs_to :reward, polymorphic: true`
  - Requires `def_column :reward_type, polymorphic_type: true`
- `has_one` : `has_one :profile`
- `has_many` : `has_many :players, foreign_key: :lv`
- `has_many :through` : `has_many :items, through: :player_items`
  - `source:` can rename the target association
