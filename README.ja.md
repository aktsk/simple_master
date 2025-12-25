# SimpleMaster

ゲーム開発の世界において、設定や定義をまとめたデータは「マスターデータ」と呼ばれます。SimpleMaster は、そのマスターデータを Rails アプリで高速に扱うためのライブラリとして開発されました。
導入するとシンプルにデータをオンメモリ化でき、ActiveRecord 風 DSL で高速にアクセス可能となります。Rails 以外の Rack アプリでも利用でき、ウェブサービス全般でデータ依存の高いアプリケーションにおいては応答を劇的に高速化できます。

> For English readers, see [README.md](README.md).

## 特徴
- **ロード後は DB クエリなし**: マスターテーブルを起動時に読み込み、以降は全てオンメモリの処理となるので、レスポンスが軽くなる。
- **馴染みの関連 API で高速参照**: `belongs_to` / `has_many` 風のインターフェースを DB ではなくオンメモリ上で処理し、N+1 を気にしなくてよい速度で動作。
- **COW フレンドリーで多プロセス共有**: レコードは freeze され、Copy-on-Write を活かしてフォークプロセス間でメモリを効率共有できる。

## ドキュメント
- 導入ガイド: [English](docs/simple_master_guide_en.md) / [日本語](docs/simple_master_guide_ja.md)
- カラム仕様: [English](docs/simple_master_columns_en.md) / [日本語](docs/simple_master_columns_ja.md)
- Dataset / Table: [English](docs/simple_master_dataset_en.md) / [日本語](docs/simple_master_dataset_ja.md)
- Association: [English](docs/simple_master_associations_en.md) / [日本語](docs/simple_master_associations_ja.md)

## ライセンス
MIT ライセンスです。詳細は [LICENSE](LICENSE) を参照してください。
