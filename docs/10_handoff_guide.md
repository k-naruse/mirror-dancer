# ハンドオフガイド（Claude チャット引き継ぎ用）

## プロジェクト概要

MirrorDancer はダンス練習用の iOS アプリ。見本動画と自分の練習動画を並べて比較再生できる。

## 環境セットアップ

```bash
cd mirror_dancer
flutter pub get
# Hive のコード生成（モデル変更時のみ）
flutter pub run build_runner build
# iOS 実機ビルド
flutter run
```

- Flutter SDK: ^3.11.1
- Xcode での Code Signing: Free Apple Developer Account
- 実機デプロイ時にコード署名エラーが出る場合は `flutter clean` + Pods/DerivedData 削除

## 設計書一覧

| ファイル | 内容 |
|---------|------|
| [01_architecture.md](01_architecture.md) | 技術スタック・ディレクトリ構成・データフロー・画面遷移 |
| [02_data_model.md](02_data_model.md) | Reference / MyVideo モデル・ER図・カスケード動作 |
| [03_state_management.md](03_state_management.md) | Riverpod プロバイダー一覧・Notifier API・画面間連携 |
| [04_screen_compare_tab.md](04_screen_compare_tab.md) | 比較画面の詳細設計（タイムライン・トリム・オフセット） |
| [05_screen_reference_tab.md](05_screen_reference_tab.md) | 見本動画画面の詳細設計 |
| [06_screen_my_videos_tab.md](06_screen_my_videos_tab.md) | 自分の動画画面の詳細設計 |
| [07_screen_settings_tab.md](07_screen_settings_tab.md) | 設定画面の詳細設計 |
| [08_ui_theme.md](08_ui_theme.md) | カラーパレット・テーマ・共通UIパターン |
| [09_widgets.md](09_widgets.md) | 共通ウィジェット |

## 新しいチャットへの引き継ぎ方法

新しい Claude チャットで以下のように伝える:

```
MirrorDancer というFlutterアプリの開発を続けたい。
docs/ フォルダに設計書があるので、まず全部読んでからコードを理解して。
```

## 実装済み機能

- [x] 見本動画の追加・一覧・非表示・削除・メモ編集・ミラー反転
- [x] 自分の動画の追加・一覧・非表示・削除
- [x] 比較再生（横並び/縦積み自動切替）
- [x] デュアルトラックタイムライン（C案）
- [x] 同時再生/一時停止/巻き戻し/±5秒シーク
- [x] 再生速度切替（0.25x/0.5x/0.75x/1.0x）
- [x] オフセット調整（ドラッグ）
- [x] 動画トリミング（開始/終了、スライダー操作）
- [x] 単体再生モード（ループ対応）
- [x] Cupertino UI（ダークモード、黄色下線修正済み）
- [x] 空状態の統一デザイン
- [x] Hive による永続化

## 注意点

- `compare_tab.dart` が約 1690 行と大きいため、変更時は慎重に
- Cupertino ウィジェットのみ使用（Material ウィジェットは使わない）
- iOS 実機デプロイにはコード署名設定が必要
- `*.g.dart` ファイルは自動生成。手動編集しない
