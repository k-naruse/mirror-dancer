import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

Future<String?> showVideoAddModal(BuildContext context) {
  return showCupertinoModalPopup<String>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: const Text('動画を追加'),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () async {
            final picker = ImagePicker();
            final video = await picker.pickVideo(source: ImageSource.camera);
            if (ctx.mounted) Navigator.pop(ctx, video?.path);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.camera, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text('カメラで撮影'),
            ],
          ),
        ),
        CupertinoActionSheetAction(
          onPressed: () async {
            final picker = ImagePicker();
            final video = await picker.pickVideo(source: ImageSource.gallery);
            if (ctx.mounted) Navigator.pop(ctx, video?.path);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.folder, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text('フォルダから選択'),
            ],
          ),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(ctx),
        child: const Text('キャンセル'),
      ),
    ),
  );
}
