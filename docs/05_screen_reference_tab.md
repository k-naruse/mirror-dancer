# 見本動画画面（ReferenceTab）設計書

## 概要

見本動画の一覧表示・追加・管理を行う画面。
ファイル: `lib/screens/reference_tab.dart`（約 463 行）

## 画面構成

```
┌─────────────────────────────┐
│ 見本動画              [＋]   │  ← CupertinoNavigationBar
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ [▶] サムネイル領域       │ │  ← 120px 高さ、refBg 色
│ │ [ミラー]        [3本]   │ │  ← ミラーバッジ + 紐づき動画数
│ ├─────────────────────────┤ │
│ │ タイトル                 │ │
│ │ 2026-03-15              │ │
│ │ メモテキスト...           │ │
│ ├─────────────────────────┤ │
│ │ [メモ編集] | [ミラーON]  │ │  ← フッターアクション
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ （次のカード...）         │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

## 空状態

動画がない場合:
- 丸アイコン（CupertinoIcons.film、refBg 背景）
- 「見本動画がありません」
- 「右上の＋ボタンから見本動画を追加してください」
- 「見本動画を追加」ボタン

## カード構成（_ReferenceCard）

ConsumerWidget。`myVideosForRefProvider(reference.id)` で紐づく動画数を取得。

### サムネイル領域
- 高さ 120px、refBg（#0C1929）背景
- 中央に再生アイコン
- 左上: ミラーバッジ（mirror=true の場合のみ表示）
- 右上: 紐づく自分の動画数

### 情報領域
- タイトル（16px、太字）
- 作成日（12px、textSub 色）
- メモ（13px、textSub 色、メモがある場合のみ）

### フッターアクション
- 「メモ編集」: CupertinoAlertDialog + CupertinoTextField でメモ編集
- 「ミラーON/OFF」: トグル（ON 時 refAccent 色、OFF 時 textSub 色）

### スワイプアクション（Slidable）

左スワイプ:
- 非表示（オレンジ）: `hide(reference.id)`
- 削除（赤）: 確認ダイアログ → `delete(reference.id)`

### タップ動作

カード全体タップ → 比較画面へ遷移:
```dart
ref.read(selectedRefIdProvider.notifier).state = reference.id;
ref.read(compareModeProvider.notifier).state = CompareMode.comparison;
ref.read(selectedTabProvider.notifier).state = 0;
```

## 追加モーダル（_showAddReferenceDialog）

CupertinoModalPopup（ボトムシート形式）:

```
┌─────────────────────────┐
│ ━━━ (ドラッグハンドル)    │
│                         │
│   見本動画を追加          │
│                         │
│ [タイトル（必須）]        │  ← CupertinoTextField
│ [メモ（任意）]           │  ← CupertinoTextField, maxLines: 2
│                         │
│ [動画を選択]             │  ← showVideoAddModal() 呼び出し
│ or                      │
│ ✓ 動画を選択済み [変更]   │  ← 選択後の表示
│                         │
│ [      追加      ]      │  ← CupertinoButton.filled
└─────────────────────────┘
```

バリデーション:
- タイトル必須（空文字不可）
- 動画選択必須（videoPath != null）

追加処理:
```dart
ref.read(referencesProvider.notifier).add(
  title: titleController.text.trim(),
  memo: memoController.text.trim(),
  videoPath: videoPath!,
);
```
