# MirrorDancer ハンドオフ文書
生成日時: 2026-03-16

## プロジェクト概要

ダンス練習用 iOS アプリ。見本動画と自分の練習動画を並べて比較再生し、フォームの確認や練習の振り返りができる。

## 設計書の読み方

`docs/` フォルダに設計書が整備されている。以下の順で読むと全体像がつかみやすい:

1. [01_architecture.md](01_architecture.md) — 技術スタック・ディレクトリ構成・画面遷移（最初に読む）
2. [02_data_model.md](02_data_model.md) — Reference / MyVideo モデル・カスケード動作
3. [03_state_management.md](03_state_management.md) — Riverpod プロバイダー一覧・状態更新パターン
4. [04_screen_compare_tab.md](04_screen_compare_tab.md) — 比較画面の詳細（アプリの中核、最重要）
5. [05_screen_reference_tab.md](05_screen_reference_tab.md) — 見本動画画面
6. [06_screen_my_videos_tab.md](06_screen_my_videos_tab.md) — 自分の動画画面
7. [07_screen_settings_tab.md](07_screen_settings_tab.md) — 設定画面
8. [08_ui_theme.md](08_ui_theme.md) — カラーパレット・テーマ定義
9. [09_widgets.md](09_widgets.md) — 共通ウィジェット

## 現在の状態

- **ブランチ:** main（クリーン、未コミット変更なし）
- **コミット履歴:** Initial commit のみ（2コミット）
- **ビルド:** Flutter SDK ^3.11.1、`cd mirror_dancer && flutter pub get` で依存取得
- **既知の問題・バグ:** 特になし（初期リリース状態）

## 実装済み機能

- 見本動画の追加・一覧・非表示・削除・メモ編集・ミラー反転
- 自分の動画の追加・一覧・非表示・削除
- 比較再生（横並び/縦積み自動切替）
- デュアルトラックタイムライン（CustomPainter）
- 同時再生/一時停止/巻き戻し/±5秒シーク
- 再生速度切替（0.25x/0.5x/0.75x/1.0x）
- オフセット調整（タイムラインドラッグ）
- 動画トリミング（開始/終了）
- 単体再生モード（ループ対応）
- Cupertino UI（ダークモード）
- Hive による永続化

## 進行中のタスク

現在進行中のタスクなし。プロジェクト引き継ぎ後の改修待ち。

## 注意点・制約

### 技術的な注意点
- `compare_tab.dart` が約 1690 行と大きい — 変更時は影響範囲に注意
- `*.g.dart` ファイルは `build_runner` による自動生成。手動編集不可
- モデル変更時は `flutter pub run build_runner build` の再実行が必要
- iOS 実機デプロイにはコード署名設定（Free Apple Developer Account）が必要
- コード署名エラー時は `flutter clean` + Pods/DerivedData 削除

### UI ルール
- **Cupertino ウィジェットのみ使用**（Material ウィジェットは使わない）
- 日本語 UI
- ダークモードベース
- 見本動画 = 青系（refAccent #5B9BD5）、自分の動画 = 緑系（myAccent #6BCF7F）

### 設計判断の背景
- タイムラインは「C案（タイムライン型）」を採用 — 2トラック並列で見本・自分の再生位置とオフセットが視覚的にわかる
- Hive を選択（軽量・高速、シンプルなデータ構造に適合）
- Riverpod + StateNotifier パターン（Notifier 内で Hive 操作 → state 同期）

## 新しいチャットへの指示テンプレート

```
MirrorDancer という Flutter アプリの開発を続けます。

## セットアップ
1. まず docs/ フォルダの設計書を全て読んでください
2. docs/HANDOFF.md に現在の状況が書いてあります

## 次にやること
（ここに具体的なタスクを記載）

## 制約
- Cupertino ウィジェットのみ使用（Material は使わない）
- 日本語 UI
- ダークモードベース
- compare_tab.dart は約1690行あるので変更は慎重に
```
