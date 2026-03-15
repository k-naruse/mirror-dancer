# 状態管理設計書

## プロバイダー一覧

### データプロバイダー

| プロバイダー | 型 | 説明 |
|------------|------|------|
| `referencesProvider` | `StateNotifierProvider<ReferencesNotifier, List<Reference>>` | 全見本動画 |
| `myVideosProvider` | `StateNotifierProvider<MyVideosNotifier, List<MyVideo>>` | 全自分の動画 |

### 派生プロバイダー

| プロバイダー | 型 | 説明 |
|------------|------|------|
| `visibleReferencesProvider` | `Provider<List<Reference>>` | hidden=false のみ |
| `hiddenReferencesProvider` | `Provider<List<Reference>>` | hidden=true のみ |
| `visibleMyVideosProvider` | `Provider<List<MyVideo>>` | hidden=false のみ |
| `hiddenMyVideosProvider` | `Provider<List<MyVideo>>` | hidden=true のみ |
| `myVideosForRefProvider` | `Provider.family<List<MyVideo>, String>` | 指定 refId の可視動画 |

### ナビゲーション状態

| プロバイダー | 型 | 説明 |
|------------|------|------|
| `selectedTabProvider` | `StateProvider<int>` | 現在のタブ index（0-3） |
| `compareModeProvider` | `StateProvider<CompareMode>` | comparison / single |
| `selectedRefIdProvider` | `StateProvider<String?>` | 比較画面で選択中の見本動画 ID |
| `selectedMyVideoIdProvider` | `StateProvider<String?>` | 比較画面で選択中の自分の動画 ID |

## ReferencesNotifier

```dart
class ReferencesNotifier extends StateNotifier<List<Reference>> {
  // コンストラクタで Hive Box の全件を state に読み込み
  ReferencesNotifier() : super(_refBox.values.toList());

  void _sync()  // Box の最新状態を state に反映

  Future<Reference> add({title, memo, videoPath})  // 新規追加（UUID生成、日付自動付与）
  Future<void> updateMemo(id, memo)                 // メモ更新
  Future<void> toggleMirror(id)                     // ミラー反転トグル
  Future<void> hide(id)                             // 非表示（紐づく MyVideo も連動）
  Future<void> unhide(id)                           // 再表示（紐づく MyVideo も連動）
  Future<void> delete(id)                           // 削除（紐づく MyVideo もカスケード削除）
}
```

## MyVideosNotifier

```dart
class MyVideosNotifier extends StateNotifier<List<MyVideo>> {
  MyVideosNotifier() : super(_myBox.values.toList());

  void _sync()
  Future<MyVideo> add({label, refId, videoPath})    // 新規追加
  Future<void> hide(id)                              // 非表示
  Future<void> unhide(id)                            // 再表示
  Future<void> delete(id)                            // 削除
}
```

## 状態更新パターン

全 Notifier は同一パターン:

1. Hive Box からオブジェクトを取得
2. フィールドを直接変更
3. `await obj.save()` で Hive に永続化
4. `_sync()` で `state = _box.values.toList()` を実行
5. Riverpod が依存ウィジェットを自動再描画

## 画面間連携

見本動画タップ時の遷移例:

```dart
// ReferenceTab の _ReferenceCard.onTap
ref.read(selectedRefIdProvider.notifier).state = reference.id;
ref.read(compareModeProvider.notifier).state = CompareMode.comparison;
ref.read(selectedTabProvider.notifier).state = 0;  // 比較タブへ
```

自分の動画の「比較→」ボタン:

```dart
// MyVideosTab
ref.read(selectedRefIdProvider.notifier).state = video.refId;
ref.read(selectedMyVideoIdProvider.notifier).state = video.id;
ref.read(compareModeProvider.notifier).state = CompareMode.comparison;
ref.read(selectedTabProvider.notifier).state = 0;
```
