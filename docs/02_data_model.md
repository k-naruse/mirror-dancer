# データモデル設計書

## ER 図

```
Reference (1) ──── (N) MyVideo
   │                     │
   ├── id (PK)           ├── id (PK)
   ├── title              ├── label
   ├── memo               ├── refId (FK → Reference.id)
   ├── mirror             ├── date
   ├── hidden             ├── hidden
   ├── videoPath           └── videoPath
   └── createdAt
```

## Reference（見本動画）

| フィールド | 型 | HiveField | 説明 |
|-----------|------|-----------|------|
| id | String | 0 | UUID v4。Hive の key としても使用 |
| title | String | 1 | ユーザーが付けるタイトル（必須） |
| memo | String | 2 | メモ（任意、デフォルト空文字） |
| mirror | bool | 3 | ミラー反転表示フラグ（デフォルト false） |
| hidden | bool | 4 | 非表示フラグ（デフォルト false） |
| videoPath | String | 5 | ローカルファイルパス |
| createdAt | String | 6 | 作成日（ISO8601 の日付部分 YYYY-MM-DD） |

- Hive TypeId: `0`
- `copyWith()` メソッドあり

## MyVideo（自分の動画）

| フィールド | 型 | HiveField | 説明 |
|-----------|------|-----------|------|
| id | String | 0 | UUID v4。Hive の key としても使用 |
| label | String | 1 | ラベル名 |
| refId | String | 2 | 紐づく Reference の id |
| date | String | 3 | 作成日（ISO8601 の日付部分 YYYY-MM-DD） |
| hidden | bool | 4 | 非表示フラグ（デフォルト false） |
| videoPath | String | 5 | ローカルファイルパス |

- Hive TypeId: `1`
- `copyWith()` メソッドあり

## カスケード動作

| 操作 | Reference | 紐づく MyVideo |
|------|-----------|---------------|
| hide | hidden = true | 全て hidden = true |
| unhide | hidden = false | 全て hidden = false |
| delete | Box から削除 | 全て Box から削除 |

## Hive Box 構成

| Box 名 | 型 | 用途 |
|--------|------|------|
| `references` | `Box<Reference>` | 見本動画の永続化 |
| `myVideos` | `Box<MyVideo>` | 自分の動画の永続化 |

- key/value 形式: key = `id`（String）
- `_refBox.put(ref.id, ref)` で保存
- `_refBox.get(id)` で取得

## コード生成

`reference.g.dart` / `my_video.g.dart` は `hive_generator` + `build_runner` で自動生成:

```bash
flutter pub run build_runner build
```
