import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/reference.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/video_add_modal.dart';

class ReferenceTab extends ConsumerWidget {
  const ReferenceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refs = ref.watch(visibleReferencesProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('見本動画', style: TextStyle(color: AppColors.text)),
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add, color: AppColors.accent),
          onPressed: () => _showAddReferenceDialog(context, ref),
        ),
      ),
      child: SafeArea(
        child: refs.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.refBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.film,
                            size: 40, color: AppColors.refAccent),
                      ),
                      const SizedBox(height: 20),
                      const Text('見本動画がありません',
                          style: TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text('右上の＋ボタンから\n見本動画を追加してください',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSub, fontSize: 14)),
                      const SizedBox(height: 24),
                      CupertinoButton(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () =>
                            _showAddReferenceDialog(context, ref),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.add,
                                size: 18, color: AppColors.accent),
                            SizedBox(width: 8),
                            Text('見本動画を追加',
                                style:
                                    TextStyle(color: AppColors.accent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: refs.length,
                itemBuilder: (ctx, i) => _ReferenceCard(reference: refs[i]),
              ),
      ),
    );
  }

  Future<void> _showAddReferenceDialog(
      BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final memoController = TextEditingController();
    String? videoPath;

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textDim,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('見本動画を追加',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text)),
                  const SizedBox(height: 20),
                  CupertinoTextField(
                    controller: titleController,
                    placeholder: 'タイトル（必須）',
                    style: const TextStyle(color: AppColors.text),
                    placeholderStyle: const TextStyle(color: AppColors.textSub),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(14),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: memoController,
                    placeholder: 'メモ（任意）',
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.text),
                    placeholderStyle: const TextStyle(color: AppColors.textSub),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(14),
                  ),
                  const SizedBox(height: 16),
                  videoPath != null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.checkmark_circle_fill,
                                color: AppColors.myAccent, size: 20),
                            const SizedBox(width: 8),
                            const Text('動画を選択済み',
                                style: TextStyle(color: AppColors.myAccent)),
                            CupertinoButton(
                              padding: const EdgeInsets.only(left: 8),
                              onPressed: () async {
                                final path = await showVideoAddModal(ctx);
                                if (path != null) {
                                  setModalState(() => videoPath = path);
                                }
                              },
                              child: const Text('変更',
                                  style: TextStyle(fontSize: 14)),
                            ),
                          ],
                        )
                      : CupertinoButton(
                          onPressed: () async {
                            final path = await showVideoAddModal(ctx);
                            if (path != null) {
                              setModalState(() => videoPath = path);
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(CupertinoIcons.video_camera, size: 20),
                              SizedBox(width: 8),
                              Text('動画を選択'),
                            ],
                          ),
                        ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: () {
                        if (titleController.text.trim().isEmpty ||
                            videoPath == null) {
                          return;
                        }
                        ref.read(referencesProvider.notifier).add(
                              title: titleController.text.trim(),
                              memo: memoController.text.trim(),
                              videoPath: videoPath!,
                            );
                        Navigator.pop(ctx);
                      },
                      child: const Text('追加',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceCard extends ConsumerWidget {
  final Reference reference;
  const _ReferenceCard({required this.reference});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myCount = ref.watch(myVideosForRefProvider(reference.id)).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.4,
          children: [
            SlidableAction(
              onPressed: (_) =>
                  ref.read(referencesProvider.notifier).hide(reference.id),
              backgroundColor: AppColors.orange,
              foregroundColor: CupertinoColors.white,
              icon: CupertinoIcons.eye_slash,
              label: '非表示',
            ),
            SlidableAction(
              onPressed: (_) => _confirmDelete(context, ref),
              backgroundColor: AppColors.red,
              foregroundColor: CupertinoColors.white,
              icon: CupertinoIcons.delete,
              label: '削除',
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            ref.read(selectedRefIdProvider.notifier).state = reference.id;
            ref.read(compareModeProvider.notifier).state =
                CompareMode.comparison;
            ref.read(selectedTabProvider.notifier).state = 0;
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.refBg,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(CupertinoIcons.play_circle,
                            size: 48, color: AppColors.refAccent),
                      ),
                      if (reference.mirror)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: CupertinoColors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('ミラー',
                                style: TextStyle(
                                    color: AppColors.refAccent, fontSize: 11)),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.myAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('$myCount本',
                              style: const TextStyle(
                                  color: AppColors.myAccent, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reference.title,
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(reference.createdAt,
                          style: const TextStyle(
                              color: AppColors.textSub, fontSize: 12)),
                      if (reference.memo.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(reference.memo,
                            style: const TextStyle(
                                color: AppColors.textSub, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    border:
                        Border(top: BorderSide(color: AppColors.border, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          onPressed: () => _showMemoEdit(context, ref),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(CupertinoIcons.pencil, size: 16, color: AppColors.textSub),
                              SizedBox(width: 4),
                              Text('メモ編集',
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.textSub)),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 0.5, height: 30, color: AppColors.border),
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          onPressed: () => ref
                              .read(referencesProvider.notifier)
                              .toggleMirror(reference.id),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.arrow_right_arrow_left,
                                  size: 16,
                                  color: reference.mirror
                                      ? AppColors.refAccent
                                      : AppColors.textSub),
                              const SizedBox(width: 4),
                              Text(
                                  reference.mirror ? 'ミラーON' : 'ミラーOFF',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: reference.mirror
                                          ? AppColors.refAccent
                                          : AppColors.textSub)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('削除確認'),
        content: Text('「${reference.title}」と紐づく自分の動画をすべて削除しますか？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(referencesProvider.notifier).delete(reference.id);
              Navigator.pop(ctx);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showMemoEdit(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: reference.memo);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('メモ編集'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            maxLines: 3,
            placeholder: 'メモを入力',
            style: const TextStyle(fontSize: 14),
            padding: const EdgeInsets.all(10),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            onPressed: () {
              ref.read(referencesProvider.notifier).updateMemo(
                    reference.id,
                    controller.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
