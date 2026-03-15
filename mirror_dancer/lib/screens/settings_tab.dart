import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiddenMyVideos = ref.watch(hiddenMyVideosProvider);
    final hiddenRefs = ref.watch(hiddenReferencesProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('設定', style: TextStyle(color: AppColors.text)),
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            _MenuTile(
              icon: CupertinoIcons.videocam,
              label: '非表示の自分の動画',
              count: hiddenMyVideos.length,
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (_) => const _HiddenMyVideosScreen()),
              ),
            ),
            const SizedBox(height: 1),
            _MenuTile(
              icon: CupertinoIcons.film,
              label: '非表示の見本動画',
              count: hiddenRefs.length,
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (_) => const _HiddenReferencesScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style:
                      const TextStyle(color: AppColors.text, fontSize: 15)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$count',
                  style: const TextStyle(
                      color: AppColors.textSub, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right,
                color: AppColors.textSub, size: 16),
          ],
        ),
      ),
    );
  }
}

class _HiddenMyVideosScreen extends ConsumerWidget {
  const _HiddenMyVideosScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(hiddenMyVideosProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('非表示の自分の動画',
            style: TextStyle(color: AppColors.text)),
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        child: videos.isEmpty
            ? const Center(
                child: Text('非表示の動画はありません',
                    style: TextStyle(color: AppColors.textSub)))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: videos.length,
                itemBuilder: (ctx, i) {
                  final v = videos[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Slidable(
                      startActionPane: ActionPane(
                        motion: const BehindMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (_) => ref
                                .read(myVideosProvider.notifier)
                                .delete(v.id),
                            backgroundColor: AppColors.red,
                            foregroundColor: CupertinoColors.white,
                            icon: CupertinoIcons.delete,
                            label: '削除',
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.myBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(CupertinoIcons.videocam,
                                  color: AppColors.myAccent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(v.label,
                                      style: const TextStyle(
                                          color: AppColors.text)),
                                  Text(v.date,
                                      style: const TextStyle(
                                          color: AppColors.textSub,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => ref
                                  .read(myVideosProvider.notifier)
                                  .unhide(v.id),
                              child: const Text('再表示',
                                  style:
                                      TextStyle(color: AppColors.accent, fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _HiddenReferencesScreen extends ConsumerWidget {
  const _HiddenReferencesScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refs = ref.watch(hiddenReferencesProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('非表示の見本動画',
            style: TextStyle(color: AppColors.text)),
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        child: refs.isEmpty
            ? const Center(
                child: Text('非表示の見本動画はありません',
                    style: TextStyle(color: AppColors.textSub)))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: refs.length,
                itemBuilder: (ctx, i) {
                  final r = refs[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Slidable(
                      startActionPane: ActionPane(
                        motion: const BehindMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (_) {
                              showCupertinoDialog(
                                context: ctx,
                                builder: (dCtx) => CupertinoAlertDialog(
                                  title: const Text('削除確認'),
                                  content: Text(
                                      '「${r.title}」と紐づく自分の動画もすべて削除されます'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('キャンセル'),
                                      onPressed: () =>
                                          Navigator.pop(dCtx),
                                    ),
                                    CupertinoDialogAction(
                                      isDestructiveAction: true,
                                      onPressed: () {
                                        ref
                                            .read(referencesProvider
                                                .notifier)
                                            .delete(r.id);
                                        Navigator.pop(dCtx);
                                      },
                                      child: const Text('削除'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            backgroundColor: AppColors.red,
                            foregroundColor: CupertinoColors.white,
                            icon: CupertinoIcons.delete,
                            label: '削除',
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.refBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(CupertinoIcons.film,
                                  color: AppColors.refAccent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(r.title,
                                      style: const TextStyle(
                                          color: AppColors.text)),
                                  Text(r.createdAt,
                                      style: const TextStyle(
                                          color: AppColors.textSub,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => ref
                                  .read(referencesProvider.notifier)
                                  .unhide(r.id),
                              child: const Text('再表示',
                                  style:
                                      TextStyle(color: AppColors.accent, fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
