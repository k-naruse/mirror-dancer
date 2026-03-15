# UI テーマ設計書

## デザイン方針

- iOS ネイティブ UI（Cupertino ウィジェット）
- ダークモードベース
- 見本動画 = 青系、自分の動画 = 緑系 で色分け

## カラーパレット

### ベースカラー

| 定数名 | HEX | 用途 |
|--------|-----|------|
| `bg` | #0F0F0F | 画面背景 |
| `surface` | #1A1A1A | カード・モーダル背景 |
| `surfaceHover` | #242424 | ホバー・選択時背景 |
| `border` | #2A2A2A | ボーダー |

### テキストカラー

| 定数名 | HEX | 用途 |
|--------|-----|------|
| `text` | #E8E8E8 | 主要テキスト |
| `textSub` | #777777 | サブテキスト・日付・メモ |
| `textDim` | #555555 | 控えめなテキスト・ドラッグハンドル |

### アクセントカラー

| 定数名 | HEX | 用途 |
|--------|-----|------|
| `accent` | #4ECDC4 | メインアクセント（ティール） |
| `accentDim` | #184ECDC4 | アクセント薄め（ボタン背景） |
| `red` | #FF6B6B | 削除・破壊的アクション |
| `orange` | #F0A050 | 非表示アクション |

### 動画カテゴリカラー

| 定数名 | HEX | 用途 |
|--------|-----|------|
| `refBg` | #0C1929 | 見本動画背景（暗い青） |
| `myBg` | #0C2919 | 自分の動画背景（暗い緑） |
| `refAccent` | #5B9BD5 | 見本動画アクセント（青） |
| `myAccent` | #6BCF7F | 自分の動画アクセント（緑） |

### タブバー

| 定数名 | HEX | 用途 |
|--------|-----|------|
| `tabBg` | #141414 | タブバー背景 |
| `tabBorder` | #222222 | タブバー上部ボーダー |

## CupertinoThemeData

```dart
CupertinoThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.accent,        // ティール
  scaffoldBackgroundColor: AppColors.bg,  // #0F0F0F
  barBackgroundColor: AppColors.surface,  // #1A1A1A
  textTheme: CupertinoTextThemeData(
    textStyle: TextStyle(color: text, fontSize: 16, decoration: none),
    navTitleTextStyle: TextStyle(color: text, fontSize: 17, w600, decoration: none),
    navLargeTitleTextStyle: TextStyle(color: text, fontSize: 34, bold, decoration: none),
    actionTextStyle: TextStyle(color: accent, fontSize: 17, decoration: none),
  ),
)
```

全テキストスタイルに `decoration: TextDecoration.none` を指定し、CupertinoWidget 内での黄色アンダーライン表示を防止。

## 共通 UI パターン

### カード

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border),
  ),
)
```

### 空状態

```
[丸アイコン（80x80、カテゴリ背景色）]
タイトル（16px、太字）
説明テキスト（14px、textSub、center揃え）
[アクションボタン（accent 薄色背景、丸角10）]
```

### モーダル（ボトムシート）

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  // ドラッグハンドル: 40x4, textDim 色, 角丸2
)
```

### スワイプアクション

Slidable + BehindMotion, extentRatio: 0.4:
- 非表示: orange 背景, eye_slash アイコン
- 削除: red 背景, delete アイコン

### テキスト入力

```dart
CupertinoTextField(
  style: TextStyle(color: AppColors.text),
  placeholderStyle: TextStyle(color: AppColors.textSub),
  decoration: BoxDecoration(
    color: AppColors.bg,
    borderRadius: BorderRadius.circular(10),
  ),
  padding: EdgeInsets.all(14),
)
```
