# SimpleMaster 導入ガイド

## 目的
- マスターデータを Rails/ActiveRecord とは別に高速に扱う
- Ruby オブジェクトとして参照でき、関連づけやキャッシュを定義できる
- DB がなくても扱え、用途に応じて複数の dataset を切り替えられる

## インストール
Gemfile に追加して bundle します。

```ruby
gem "simple_master"
```

```bash
bundle install
```

## 初期化
アプリ起動時に SimpleMaster を初期化し、データセットを読み込ませます。

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

※ JSON fixture を読み込む場合は後述の `JsonLoader` を使います。

## Master クラス定義
`ApplicationMaster` をベースに Master を作ります。

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

## データロード (DB / Fixture)
### DB から読み込む
標準の `QueryLoader` で DB のテーブルから読み込みます。

```ruby
loader = SimpleMaster::Loader::QueryLoader.new
$current_dataset = SimpleMaster::Storage::Dataset.new(loader: loader)
$current_dataset.load
```

### Loader を自作する
例：独自ローダを用意して JSON を読み込みます。

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

※ STI を使う場合は `type` を見てクラス分岐する実装を追加してください（例: [dummy/lib/json_loader.rb](dummy/lib/json_loader.rb)）。

```ruby
loader = JsonLoader.new
$current_dataset = SimpleMaster::Storage::Dataset.new(loader: loader)
$current_dataset.load
```

## ActiveRecord 連携
ActiveRecord のモデルから Master を参照する場合は Extension を使います。

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

## テスト用設定
テストケースごとにリセットするため、Dataset を都度作るように設定します。
またテストでは通常と違い、データの一時保存や関連付け保存等が必要なため、`SimpleMaster::Master::Editable` と `TestTable` 利用するとよりスムーズとなります。
例えば、RSpec ではこのように設定します。

```ruby
ApplicationMaster.prepend(SimpleMaster::Master::Editable)

RSpec.configure do |config|
  config.around do |example|
    dataset = SimpleMaster::Storage::Dataset.new(table_class: SimpleMaster::Storage::TestTable)
    SimpleMaster.use_dataset(dataset) { example.run }
  end
end
```

## 便利メソッド
- `SimpleMaster.use_dataset(dataset) { ... }` : 一時的に dataset を差し替える
- `cache_method` / `cache_class_method` : 高速なキャッシュを定義
- `enum` / `bitmask` / `globalize` : カラム拡張

## 補足
- 本番では `SimpleMaster::Master::Editable` は使わず、テスト用途のみ推奨
- データソースに合わせて `Loader` を差し替える運用を想定
