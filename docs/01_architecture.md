# MirrorDancer アーキテクチャ設計書

## 概要

MirrorDancer は、ダンス練習動画と見本動画を並べて比較再生するための iOS アプリ。
Flutter + Cupertino ウィジェットで構築し、iOS ネイティブの UX を実現する。

## 技術スタック

| レイヤー | 技術 | バージョン |
|---------|------|-----------|
| UI フレームワーク | Flutter (Cupertino) | SDK ^3.11.1 |
| 状態管理 | flutter_riverpod | ^2.6.1 |
| ローカル DB | Hive (hive_flutter) | ^2.2.3 / ^1.1.0 |
| 動画再生 | video_player | ^2.9.2 |
| メディア取得 | image_picker | ^1.1.2 |
| スライドアクション | flutter_slidable | ^3.1.1 |
| ID 生成 | uuid | ^4.5.1 |
| 日付フォーマット | intl | ^0.19.0 |

## ディレクトリ構成

```
mirror_dancer/lib/
├── main.dart                  # エントリーポイント（Hive初期化 + ProviderScope）
├── theme/
│   └── app_theme.dart         # AppColors + CupertinoThemeData
├── models/
│   ├── reference.dart         # 見本動画モデル（HiveObject）
│   ├── reference.g.dart       # Hive TypeAdapter（自動生成）
│   ├── my_video.dart          # 自分の動画モデル（HiveObject）
│   └── my_video.g.dart        # Hive TypeAdapter（自動生成）
├── providers/
│   └── app_state.dart         # Riverpod プロバイダー群
├── screens/
│   ├── home_shell.dart        # CupertinoTabScaffold（4タブ）
│   ├── compare_tab.dart       # 比較再生画面（最大・最重要）
│   ├── reference_tab.dart     # 見本動画一覧
│   ├── my_videos_tab.dart     # 自分の動画一覧
│   └── settings_tab.dart      # 設定（非表示アイテム管理）
└── widgets/
    └── video_add_modal.dart   # 動画追加モーダル（カメラ/ギャラリー選択）
```

## データフロー

```
[Hive Box] ←→ [StateNotifier] ←→ [Provider] ←→ [ConsumerWidget]
                                        ↓
                              [Derived Provider]（フィルタ・集計）
```

1. Hive Box がローカルストレージとして永続化を担当
2. StateNotifier が CRUD 操作を実行し、操作後に state を再同期
3. Provider / Derived Provider がウィジェットにリアクティブにデータを供給
4. ConsumerWidget が ref.watch() で自動的に再描画

## 画面遷移

```
HomeShell (CupertinoTabScaffold)
├── Tab 0: CompareTab（比較）
│   ├── 比較モード: 見本 + 自分の動画を並べて再生
│   └── 単体モード: 自分の動画を単体再生
├── Tab 1: ReferenceTab（見本動画）
│   └── タップ → selectedRefId 設定 → Tab 0 へ遷移
├── Tab 2: MyVideosTab（自分の動画）
│   └── 「比較→」ボタン → selectedRefId/MyVideoId 設定 → Tab 0 へ遷移
└── Tab 3: SettingsTab（設定）
    ├── 非表示の自分の動画一覧
    └── 非表示の見本動画一覧
```

## 初期化フロー (main.dart)

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Hive.initFlutter()` でファイルシステム初期化
3. `ReferenceAdapter` / `MyVideoAdapter` をレジスタ
4. `references` / `myVideos` の Box をオープン
5. `ProviderScope` でラップした `MirrorDancerApp` を起動
6. `CupertinoApp` に `cupertinoTheme()` を適用
