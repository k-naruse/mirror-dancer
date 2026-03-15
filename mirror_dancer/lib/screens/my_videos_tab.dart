import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/my_video.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

enum _GroupMode { date, reference }

class MyVideosTab extends ConsumerStatefulWidget {
  const MyVideosTab({super.key});

  @override
  ConsumerState<MyVideosTab> createState() => _MyVideosTabState();
}

class _MyVideosTabState extends ConsumerState<MyVideosTab> {
  _GroupMode _groupMode = _GroupMode.date;
  final Set<String> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(visibleMyVideosProvider);
    final refs = ref.watch(visibleReferencesProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      navigationBar: CupertinoNavigationBar(
        middle: Text('自分の動画 (${videos.length})',
            style: const TextStyle(color: AppColors.text)),
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (videos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<_GroupMode>(
                    groupValue: _groupMode,
                    backgroundColor: AppColors.surface,
                    thumbColor: AppColors.accent.withValues(alpha: 0.2),
                    children: const {
                      _GroupMode.date: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.calendar, size: 14, color: AppColors.text),
                            SizedBox(width: 6),
                            Text('日付', style: TextStyle(color: AppColors.text, fontSize: 13)),
                          ],
                        ),
                      ),
                      _GroupMode.reference: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.film, size: 14, color: AppColors.text),
                            SizedBox(width: 6),
                            Text('見本別', style: TextStyle(color: AppColors.text, fontSize: 13)),
                          ],
                        ),
                      ),
                    },
                    onValueChanged: (val) {
                      if (val != null) setState(() => _groupMode = val);
                    },
                  ),
                ),
              ),
            Expanded(
              child: videos.isEmpty
                  ? _buildEmptyState(context)
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: _buildGroups(videos, refs),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasRefs = ref.watch(visibleReferencesProvider).isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.myBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.videocam,
                  size: 40, color: AppColors.myAccent),
            ),
            const SizedBox(height: 20),
            const Text('自分の動画がありません',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              hasRefs
                  ? '見本動画タブから見本を選んで、\n比較画面で自分の動画を撮影・追加しましょう'
                  : 'まず見本動画を追加してください。\n見本動画タブから追加できます。',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSub, fontSize: 14),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              color: AppColors.accent.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              borderRadius: BorderRadius.circular(10),
              onPressed: () {
                ref.read(selectedTabProvider.notifier).state = 1;
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(hasRefs ? CupertinoIcons.film : CupertinoIcons.add,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(hasRefs ? '見本動画を見る' : '見本動画を追加',
                      style: const TextStyle(color: AppColors.accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroups(List<MyVideo> videos, List<dynamic> refs) {
    final Map<String, List<MyVideo>> groups = {};

    if (_groupMode == _GroupMode.date) {
      for (final v in videos) {
        groups.putIfAbsent(v.date, () => []).add(v);
      }
      final sorted = groups.keys.toList()..sort((a, b) => b.compareTo(a));
      return sorted.expand((key) {
        final label = _formatDate(key);
        return [_buildGroup(key, label, groups[key]!)];
      }).toList();
    } else {
      for (final v in videos) {
        groups.putIfAbsent(v.refId, () => []).add(v);
      }
      return groups.entries.map((e) {
        final refTitle = refs
                .where((r) => r.id == e.key)
                .map((r) => r.title as String)
                .firstOrNull ??
            '不明な見本';
        return _buildGroup(e.key, refTitle, e.value);
      }).toList();
    }
  }

  Widget _buildGroup(String key, String label, List<MyVideo> videos) {
    final collapsed = _collapsed.contains(key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            if (collapsed) {
              _collapsed.remove(key);
            } else {
              _collapsed.add(key);
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(
                  collapsed
                      ? CupertinoIcons.chevron_right
                      : CupertinoIcons.chevron_down,
                  color: AppColors.textSub,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(width: 8),
                Text('${videos.length}本',
                    style: const TextStyle(
                        color: AppColors.textSub, fontSize: 12)),
              ],
            ),
          ),
        ),
        if (!collapsed)
          ...videos.map((v) => _MyVideoRow(
                video: v,
                subInfo: _groupMode == _GroupMode.date
                    ? _getRefTitle(v.refId)
                    : v.date,
              )),
        const SizedBox(height: 4),
      ],
    );
  }

  String _getRefTitle(String refId) {
    final refs = ref.read(visibleReferencesProvider);
    return refs
            .where((r) => r.id == refId)
            .map((r) => r.title)
            .firstOrNull ??
        '不明';
  }

  String _formatDate(String dateStr) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final date = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final diff = today.difference(date).inDays;
    if (diff == 0) return '今日';
    if (diff == 1) return '昨日';
    return '${parts[1]}/${parts[2]}';
  }
}

class _MyVideoRow extends ConsumerWidget {
  final MyVideo video;
  final String subInfo;

  const _MyVideoRow({required this.video, required this.subInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Slidable(
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.4,
          children: [
            SlidableAction(
              onPressed: (_) =>
                  ref.read(myVideosProvider.notifier).hide(video.id),
              backgroundColor: AppColors.orange,
              foregroundColor: CupertinoColors.white,
              icon: CupertinoIcons.eye_slash,
              label: '非表示',
            ),
            SlidableAction(
              onPressed: (_) =>
                  ref.read(myVideosProvider.notifier).delete(video.id),
              backgroundColor: AppColors.red,
              foregroundColor: CupertinoColors.white,
              icon: CupertinoIcons.delete,
              label: '削除',
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            ref.read(selectedMyVideoIdProvider.notifier).state = video.id;
            ref.read(compareModeProvider.notifier).state = CompareMode.single;
            ref.read(selectedTabProvider.notifier).state = 0;
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.myBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.videocam,
                      color: AppColors.myAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(video.label,
                          style: const TextStyle(
                              color: AppColors.text, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(subInfo,
                          style: const TextStyle(
                              color: AppColors.textSub, fontSize: 12)),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () {
                    ref.read(selectedMyVideoIdProvider.notifier).state =
                        video.id;
                    ref.read(selectedRefIdProvider.notifier).state =
                        video.refId;
                    ref.read(compareModeProvider.notifier).state =
                        CompareMode.comparison;
                    ref.read(selectedTabProvider.notifier).state = 0;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accent, width: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('比較 →',
                        style: TextStyle(
                            color: AppColors.accent, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
