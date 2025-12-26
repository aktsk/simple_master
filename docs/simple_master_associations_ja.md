# SimpleMaster Association 仕様 (日本語)

> English version: [simple_master_associations_en.md](simple_master_associations_en.md)

## 全体説明
SimpleMaster の Association は `belongs_to` / `has_one` / `has_many` / `has_many :through` を提供します。

## 定義方法
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

対象が `SimpleMaster::Master` か `ActiveRecord::Base` かで参照方法が変わります。

- Master 同士: `all_by` / `find_by` を使った参照
  - 取得が高速なため、都度引き直しとなります。利用時に呼ぶ回数多いなら、変数に格納してください。
- ActiveRecord: `simple_master_connection` で DB 参照
  - `belongs_to_store` / `has_many_store` (RequestStore) に保持されるため、リクエストごとにキャッシュが効きます。

## 共通オプション
### `class_name:`
- 例: `belongs_to :reward, class_name: "Weapon"`
- 明示的に参照先クラスを指定します。

### `foreign_key:`
- 例: `has_many :players, foreign_key: :lv`
- 外部キー名を指定します。

### `primary_key:`
- 例: `belongs_to :level, primary_key: :lv`
- 参照先のキーを指定します（デフォルトは `:id`）。

## Association 種別
- `belongs_to` : `belongs_to :enemy`
- `belongs_to (polymorphic)` : `belongs_to :reward, polymorphic: true`
  - 前提: `def_column :reward_type, polymorphic_type: true`
- `has_one` : `has_one :profile`
- `has_many` : `has_many :players, foreign_key: :lv`
- `has_many :through` : `has_many :items, through: :player_items`
  - `source:` を指定すると参照先の名前を変更できます。
