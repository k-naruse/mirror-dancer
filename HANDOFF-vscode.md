# MirrorDancer - VS Code（Claude Code）への引き継ぎ手順

## 準備

1. 以下の3ファイルをダウンロードしてプロジェクト用のフォルダに配置:
   - `design-spec.md` — 設計書
   - `dance-app.jsx` — Reactプロトタイプ
   - `TODO-usability.md` — ユーザビリティ評価チェックリスト

## 指示テンプレート（そのままコピーして使える）

```
以下のファイルを読んでFlutterアプリを作成してください。

- design-spec.md: アプリの設計書（画面仕様・データ構造・遷移図・技術要件）
- dance-app.jsx: Reactで作ったインタラクティブなプロトタイプ（UIの参考）
- TODO-usability.md: 今後の評価観点（今は参照のみ）

作業の進め方:
1. design-spec.mdの設計書をすべて読み込む
2. dance-app.jsxのUIコンポーネント構成を参考にする
3. Flutterプロジェクトを新規作成（flutter create mirror_dancer）
4. 以下の順で実装:
   a. データモデル（Reference, MyVideo）とローカル保存（Hive or SQLite）
   b. 4タブのナビゲーション（比較・見本動画・自分の動画・設定）
   c. 比較タブ（比較モード + 単体再生モード切替）
   d. 見本動画タブ（一覧・追加・スワイプ操作）
   e. 自分の動画タブ（日付/見本別表示・折りたたみ・スワイプ操作）
   f. 設定タブ（非表示動画管理）
   g. 動画再生（video_player）と撮影/選択（image_picker）

カラースキームはダークテーマで design-spec.md の 5.3 に従ってください。
状態管理は riverpod を使ってください。
```

## 補足のヒント

- プロトタイプはReact（JSX）で書かれているが、UIレイアウトとインタラクションの仕様確認用。FlutterのWidgetに1対1で変換する必要はない
- スワイプ操作はFlutterの `Dismissible` や `flutter_slidable` パッケージで実装可能
- 動画の同期再生が技術的に最も難しい部分。まずは単体再生を完成させてから同期機能を追加する順序がおすすめ
- プロトタイプでは動画再生はモック（UIのみ）なので、実際のVideoPlayerController統合はFlutter側で初めて実装する
