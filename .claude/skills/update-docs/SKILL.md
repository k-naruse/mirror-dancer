---
name: update-docs
description: 設計書(docs/)を現在のコードに合わせて更新する。コード変更後に設計書を最新化したいときに使う。
disable-model-invocation: true
argument-hint: "[対象ファイル名 or 空欄で全件]"
allowed-tools: Read, Glob, Grep, Edit, Write, Agent, Bash
---

# 設計書更新スキル

## 目的

`docs/` フォルダの設計書を、現在の実装コードに合わせて更新する。

## 設計書一覧と対応するソース

| 設計書 | 対応ソース |
|-------|-----------|
| `docs/01_architecture.md` | `lib/` 全体の構成、`pubspec.yaml` |
| `docs/02_data_model.md` | `lib/models/reference.dart`, `lib/models/my_video.dart` |
| `docs/03_state_management.md` | `lib/providers/app_state.dart` |
| `docs/04_screen_compare_tab.md` | `lib/screens/compare_tab.dart` |
| `docs/05_screen_reference_tab.md` | `lib/screens/reference_tab.dart` |
| `docs/06_screen_my_videos_tab.md` | `lib/screens/my_videos_tab.dart` |
| `docs/07_screen_settings_tab.md` | `lib/screens/settings_tab.dart` |
| `docs/08_ui_theme.md` | `lib/theme/app_theme.dart` |
| `docs/09_widgets.md` | `lib/widgets/` 配下 |
| `docs/10_handoff_guide.md` | 実装済み機能の総まとめ |

## 手順

1. **対象の特定**: 引数 `$ARGUMENTS` が指定されていればそのファイルのみ、空なら全件を対象にする

2. **差分の検出**: 対応するソースコードを読み、設計書の内容と比較する。以下の観点でチェック:
   - 新しいファイル・クラス・プロバイダーが追加されていないか
   - 既存のフィールド・メソッド・UI構成が変更されていないか
   - 削除されたコードが設計書に残っていないか
   - カラーコードや定数値が変わっていないか

3. **更新の実行**: 差分がある設計書のみ Edit ツールで更新する。変更がないファイルはスキップ

4. **新規ファイル対応**: `lib/` 配下に設計書でカバーされていない新しいファイルがあれば、適切な設計書に追記するか、新しい設計書ファイルを作成する

5. **結果報告**: 更新したファイルと主な変更点を箇条書きで報告する

## 更新時のルール

- 設計書のフォーマット・構成は既存のスタイルに合わせる
- ASCII図は実際のUIレイアウトに合わせて正確に描く
- 日本語で記述する
- コード例は実装と一致させる（古いコードを残さない）
- `10_handoff_guide.md` の「実装済み機能」チェックリストも忘れず更新する
