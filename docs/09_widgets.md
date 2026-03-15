# 共通ウィジェット設計書

## video_add_modal.dart

### showVideoAddModal()

動画の追加元を選択する CupertinoActionSheet。

```dart
Future<String?> showVideoAddModal(BuildContext context)
```

**戻り値:** 選択した動画のファイルパス（キャンセル時 null）

**選択肢:**
1. 「カメラで撮影」: `ImagePicker().pickVideo(source: ImageSource.camera)`
2. 「フォルダから選択」: `ImagePicker().pickVideo(source: ImageSource.gallery)`
3. 「キャンセル」

**使用箇所:**
- ReferenceTab: 見本動画追加モーダル内
- CompareTab: 自分の動画追加時（見本に紐づけて追加）

**注意点:**
- `ctx.mounted` チェック後に `Navigator.pop` を呼ぶ（非同期処理後のコンテキスト安全性）
- image_picker の iOS 権限設定が必要（Info.plist に NSCameraUsageDescription, NSPhotoLibraryUsageDescription）
