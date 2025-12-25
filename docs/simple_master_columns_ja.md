# SimpleMaster カラム仕様 (日本語)

## 全体説明
SimpleMaster のカラムは `def_column` で定義し、ロード時に型変換・キャッシュ・補助メソッドを自動生成します。
`type` や各種 DSL によって、変換ルールや追加メソッドが決まります。

```ruby
class Weapon < ApplicationMaster
  def_column :id
  def_column :name, type: :string
  def_column :attack, type: :float
  def_column :rarity

  enum :rarity, { common: 0, rare: 1, epic: 2 }
end
```

## 共通オプション
### `type:`
- 例: `def_column :attack, type: :float`
- 対応タイプは「カラムタイプ別一覧」を参照してください。

### `group_key:`
- 例: `def_column :lv, type: :integer, group_key: true`
- もしくは `group_key :lv` でも指定できます。

### `db_column_name:`
- DB 側のカラム名が異なる場合に使います。
- 例: `def_column :start_at, type: :time, db_column_name: :start_time`

### `globalize:`
- 言語による差分が定義でき、`I18n.locale` に応じた値を返すようになります。
- 例: `def_column :name, globalize: true`
- もしくは `globalize :name` でも指定できます。
- `@_globalized_name` に翻訳文が `{ en: "Storm Edge", ja: "ストームエッジ" }` のように入ります。
- `id` / `enum` / `bitmask` / `sti` / `polymorphic_type` では利用できません。
- `group_key` とは併用できません。

## カラムタイプ別一覧

### id (IdColumn)
**指定方法**
```ruby
def_column :id
```
**挙動**
- 代入時に `to_i` で変換。
- テスト用の更新時に `id_hash` を再構築するための処理が入ります。

### integer
**指定方法**
```ruby
def_column :lv, type: :integer
```
**挙動**
- 代入時に nil 以外は `to_i` で変換されます（空文字は `nil` に）。

### float
**指定方法**
```ruby
def_column :attack, type: :float
```
**挙動**
- 代入時に nil 以外は `to_f` で変換されます（空文字は `nil` に）。

### string
**指定方法**
```ruby
def_column :name, type: :string
```
**挙動**
- 代入時に nil 以外は `to_s` で変換されます。
- メモリ節約のために、オブジェクトはキャッシュされ、同じ値ならオブジェクトは流用されます。（object_cache）

### symbol
**指定方法**
```ruby
def_column :kind, type: :symbol
```
**挙動**
- 代入時に nil 以外は `to_s` + `to_sym` で変換されます。
- SQL/CSV 用には文字列として出力されます。

### boolean
**指定方法**
```ruby
def_column :is_boss, type: :boolean
```
**挙動**
- `Integer` は 0/1、`String` は "true" / "1" で判定。
- `name?` のメソッドが追加されます。
- SQL/CSV 出力時は 0/1 に変換されます。

### json
**指定方法**
```ruby
def_column :info, type: :json
```
**オプション**
- `symbolize_names: true` を指定すると JSON 文字列をシンボルキーに変換します。

**挙動**
- 文字列の場合は `JSON.parse`。
- SQL/CSV 出力時は `JSON.generate` で文字列化されます。
- 注意点: 文字列以外の代入は、`symbolize_names` によるキー変換は行われません。

### time
**指定方法**
```ruby
def_column :start_at, type: :time
```
**オプション**
- `db_type: :time` を指定すると時刻だけの形式 (`HH:MM:SS`) で出力します。

**挙動**
- 文字列を `Date._parse` で解析して `Time` に変換します。
- 小数秒は切り捨てられます。

### enum
**指定方法**
```ruby
def_column :rarity, enum: { common: 0, rare: 1, epic: 2 }
# or
def_column :rarity
enum :rarity, { common: 0, rare: 1, epic: 2 }
```
**オプション**
- `prefix`, `suffix`: 述語メソッドに prefix / suffix を付けられます。
  - `prefix: true` で `rarity_common?` のようになります。
  - `suffix: :rarity` で `common_rarity?` のようになります。

**挙動**
- 値は `Symbol` として扱われます。
- `rarities` クラスメソッドと `rarity_before_type_cast` が追加されます。
- 述語メソッド (例: `common?`) が自動生成されます。

### bitmask
**指定方法**
```ruby
def_column :flags, type: :integer
bitmask :flags, as: [:tradeable, :soulbound, :limited]
```
**挙動**
- 配列/シンボル/整数を受け取り、内部では整数ビットに変換します。
- `flags` はシンボル配列として返ります。
- `flags_value` / `flags_value=` が追加されます。ビット列の数値が返ります。

### sti (STIタイプカラム)
**指定方法**
```ruby
def_column :type, sti: true
```
**挙動**
- `type` を文字列に変換します。
- Loader 側で `type` を見てクラス分岐する運用になります。
- `sti_base_class` と `sti_column` が定義されます。

### polymorphic_type
**指定方法**
```ruby
def_column :reward_type, polymorphic_type: true
```
**挙動**
- `belongs_to polymorphic` のタイプカラムとして使います。
- `reward_type` を文字列として保持し、`reward_type_class` を自動で設定します。
- 空文字は `nil` に変換されます。

## カラムのカスタム定義
独自のカラム型を追加する場合は `SimpleMaster::Master::Column` を継承します。
クラス名の末尾が `Column` であれば、自動で `type` が登録されます。

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

# 利用側
class Product < ApplicationMaster
  def_column :price, type: :money
end
```

- カスタムカラムのファイルはロード対象に含めてください。
- `init` をオーバーライドすると、独自メソッドの生成も可能です。
- 詳しくは [lib/simple_master/master/column.rb](lib/simple_master/master/column.rb) 定義ファイルを直接ご覧ください
