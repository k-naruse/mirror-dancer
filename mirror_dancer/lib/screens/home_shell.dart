import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'compare_tab.dart';
import 'reference_tab.dart';
import 'my_videos_tab.dart';
import 'settings_tab.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late final CupertinoTabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = CupertinoTabController(
      initialIndex: ref.read(selectedTabProvider),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(selectedTabProvider, (_, next) {
      if (_tabController.index != next) {
        _tabController.index = next;
      }
    });

    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        onTap: (i) => ref.read(selectedTabProvider.notifier).state = i,
        backgroundColor: AppColors.tabBg.withValues(alpha: 0.95),
        activeColor: AppColors.accent,
        inactiveColor: AppColors.textSub,
        border: const Border(top: BorderSide(color: AppColors.tabBorder, width: 0.5)),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.play_rectangle),
            activeIcon: Icon(CupertinoIcons.play_rectangle_fill),
            label: '比較',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.film),
            activeIcon: Icon(CupertinoIcons.film_fill),
            label: '見本動画',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.videocam),
            activeIcon: Icon(CupertinoIcons.videocam_fill),
            label: '自分の動画',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gear),
            activeIcon: Icon(CupertinoIcons.gear_solid),
            label: '設定',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const CompareTab();
          case 1:
            return const ReferenceTab();
          case 2:
            return const MyVideosTab();
          case 3:
            return const SettingsTab();
          default:
            return const CompareTab();
        }
      },
    );
  }
}
