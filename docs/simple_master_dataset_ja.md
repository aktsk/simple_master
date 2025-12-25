# SimpleMaster Dataset / Table 仕様 (日本語)

> English version: [simple_master_dataset_en.md](simple_master_dataset_en.md)

## 全体説明
SimpleMaster ではデータの実体を `Dataset` が持ち、各 Master クラスごとに `Table` が対応します。
`Loader` が外部データを読み込み、`Table` がレコードと各種キャッシュを保持します。

```
Dataset
  ├─ Table (Weapon)
  ├─ Table (Armor)
  └─ Table (Level)
```

## Dataset
### 役割
- `loader` を使って各 `Table` をロードする
- `cache` を保持し、クラス/インスタンスのキャッシュに利用する
- `diff` による差分上書きを提供する

### 基本の使い方
```ruby
loader = SimpleMaster::Loader::QueryLoader.new
dataset = SimpleMaster::Storage::Dataset.new(loader: loader)
dataset.load

SimpleMaster.use_dataset(dataset) do
  # dataset を使った処理
end
```

### 主なAPI
- `load` : 全対象テーブルをロードし、キャッシュを更新
- `reload` : `Table` の種類に応じて再ロード/アンロードを実行
- `unload` : テーブルとキャッシュをクリア
- `duplicate(diff: nil)` : dataset を複製 (diff も継承)
- `table(klass)` : 対象クラスの `Table` を取得

### 差分 (diff)
Loader から取得するデータの上にさらに変更を自動的に加えられる仕組みです。
`dataset.diff` に JSON/Hash を設定するとロード後に差分が適用されます。
`Table.apply_diff` が `id_hash` を更新し、差分レコードを上書きします。

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

### Dataset キャッシュ
`cache_read` / `cache_fetch` / `cache_write` / `cache_delete` を用意しています。
外部参照用の軽量キャッシュに使えます。ただし、メモリに保存されるので、容量にご注意ください。

## Table
### 役割
- 対象クラスのレコード配列 (`all`) を保持
- `id_hash` / `grouped_hash` を構築
- クラス/インスタンスキャッシュを更新
- STI サブクラスのサブテーブルを保持

### 主なデータ
- `all` : レコードの配列
- `id_hash` : `id` => record
- `grouped_hash` : `group_key` => grouped records
- `class_method_cache` : `cache_class_method` の結果
- `method_cache` : `cache_method` の結果

### STI とサブテーブル
STI を使うクラスでは、`sub_table` がサブクラスごとの `Table` を返します。
`update_sub_tables` が `all` からサブクラスを抽出して登録します。

## Table の種類
### Table (デフォルト)
- `Dataset` 読み込み時に全件をロードする
- `load` のタイミングで `all` / `id_hash` / `grouped_hash` を構築
- 基本的に中身は freeze されるので、Copy-on-Write が効きやすい

### OndemandTable
- `all` / `id_hash` / `grouped_hash` を初回アクセス時に構築
- 大規模データやオンデマンド参照で有効

```ruby
dataset = SimpleMaster::Storage::Dataset.new(
  table_class: SimpleMaster::Storage::OndemandTable
)
```

### TestTable
- テスト向けの軽量テーブル
- `update` / `record_updated` による差分更新を前提とする

```ruby
dataset = SimpleMaster::Storage::Dataset.new(
  table_class: SimpleMaster::Storage::TestTable
)
```

## Loader
`Loader` は `read_raw` と `build_records` を実装して使います。
既存の `QueryLoader` / `MarshalLoader` のほか、アプリケーションの要件に応じて Loader を作れます。

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
