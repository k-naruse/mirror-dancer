import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../models/my_video.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/video_add_modal.dart';

class CompareTab extends ConsumerStatefulWidget {
  const CompareTab({super.key});

  @override
  ConsumerState<CompareTab> createState() => _CompareTabState();
}

class _CompareTabState extends ConsumerState<CompareTab> {
  VideoPlayerController? _refController;
  VideoPlayerController? _myController;

  double _speed = 1.0;
  double _offsetSeconds = 0.0;
  bool _syncPlaying = false;

  static const _speeds = [0.25, 0.5, 0.75, 1.0];

  String? _loadedRefId;
  String? _loadedMyVideoId;

  // Trim state
  Duration _refTrimStart = Duration.zero;
  Duration? _refTrimEnd;
  Duration _myTrimStart = Duration.zero;
  Duration? _myTrimEnd;
  bool _refShowTrimIcon = false;
  bool _myShowTrimIcon = false;

  // Timeline interaction
  Timer? _positionTimer;
  bool _isDraggingOffset = false;

  // ── Duration/position helpers ──
  double get _refDuration {
    if (_refController?.value.isInitialized != true) return 0;
    return _refController!.value.duration.inMilliseconds / 1000.0;
  }

  double get _myDuration {
    if (_myController?.value.isInitialized != true) return 0;
    return _myController!.value.duration.inMilliseconds / 1000.0;
  }

  double get _refPosition {
    if (_refController?.value.isInitialized != true) return 0;
    return _refController!.value.position.inMilliseconds / 1000.0;
  }

  double get _myPosition {
    if (_myController?.value.isInitialized != true) return 0;
    return _myController!.value.position.inMilliseconds / 1000.0;
  }

  double get _timelineStart =>
      _offsetSeconds < 0 ? _offsetSeconds : 0;

  double get _timelineEnd {
    final re = _refDuration > 0 ? _refDuration : 0.0;
    final me = _myDuration > 0 ? _offsetSeconds + _myDuration : 0.0;
    final e = max(re, me);
    return e > _timelineStart ? e : _timelineStart + 1;
  }

  double get _timelineRange => _timelineEnd - _timelineStart;

  @override
  void dispose() {
    _positionTimer?.cancel();
    _refController?.removeListener(_onRefPlayback);
    _myController?.removeListener(_onMyPlayback);
    _refController?.dispose();
    _myController?.dispose();
    super.dispose();
  }

  void _initRefVideo(String path) {
    _refController?.removeListener(_onRefPlayback);
    _refController?.dispose();
    _refTrimStart = Duration.zero;
    _refTrimEnd = null;
    _refShowTrimIcon = false;
    _refController = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        if (mounted) {
          _refController!.addListener(_onRefPlayback);
          setState(() {});
        }
      });
  }

  void _initMyVideo(String path) {
    _myController?.removeListener(_onMyPlayback);
    _myController?.dispose();
    _myTrimStart = Duration.zero;
    _myTrimEnd = null;
    _myShowTrimIcon = false;
    _myController = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        if (mounted) {
          _myController!.addListener(_onMyPlayback);
          setState(() {});
        }
      });
  }

  void _onRefPlayback() {
    if (_refTrimEnd != null &&
        _refController != null &&
        _refController!.value.isPlaying) {
      final pos = _refController!.value.position;
      if (pos >= _refTrimEnd!) {
        _refController!.pause();
        _refController!.seekTo(_refTrimStart);
        if (_syncPlaying && _myController != null) {
          _myController!.pause();
          _myController!.seekTo(_myTrimStart);
        }
        if (mounted) {
          _stopPositionTimer();
          setState(() => _syncPlaying = false);
        }
      }
    }
  }

  void _onMyPlayback() {
    if (_myTrimEnd != null &&
        _myController != null &&
        _myController!.value.isPlaying) {
      final pos = _myController!.value.position;
      if (pos >= _myTrimEnd!) {
        _myController!.pause();
        _myController!.seekTo(_myTrimStart);
        if (_syncPlaying && _refController != null) {
          _refController!.pause();
          _refController!.seekTo(_refTrimStart);
        }
        if (mounted) {
          _stopPositionTimer();
          setState(() => _syncPlaying = false);
        }
      }
    }
  }

  void _autoLoadVideos(dynamic currentRef, MyVideo? selectedMyVideo) {
    if (currentRef != null && currentRef.id != _loadedRefId) {
      _loadedRefId = currentRef.id as String;
      final path = currentRef.videoPath as String;
      if (path.isNotEmpty) _initRefVideo(path);
      if (selectedMyVideo != null && selectedMyVideo.refId != currentRef.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedMyVideoIdProvider.notifier).state = null;
        });
        _myController?.dispose();
        _myController = null;
        _loadedMyVideoId = null;
        return;
      }
    }
    if (selectedMyVideo != null && selectedMyVideo.id != _loadedMyVideoId) {
      _loadedMyVideoId = selectedMyVideo.id;
      if (selectedMyVideo.videoPath.isNotEmpty) {
        _initMyVideo(selectedMyVideo.videoPath);
      }
    }
  }

  void _cycleSpeed() {
    final idx = _speeds.indexOf(_speed);
    setState(() {
      _speed = _speeds[(idx + 1) % _speeds.length];
    });
    _refController?.setPlaybackSpeed(_speed);
    _myController?.setPlaybackSpeed(_speed);
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> _syncPlay() async {
    final hasRef = _refController?.value.isInitialized ?? false;
    final hasMy = _myController?.value.isInitialized ?? false;
    if (!hasRef && !hasMy) return;

    if (_syncPlaying) {
      if (hasRef) await _refController!.pause();
      if (hasMy) await _myController!.pause();
      _stopPositionTimer();
      setState(() => _syncPlaying = false);
    } else {
      if (hasRef) {
        _refController!.setPlaybackSpeed(_speed);
        final extra = _offsetSeconds < 0
            ? Duration(milliseconds: (-_offsetSeconds * 1000).round())
            : Duration.zero;
        await _refController!.seekTo(_refTrimStart + extra);
      }
      if (hasMy) {
        _myController!.setPlaybackSpeed(_speed);
        final extra = _offsetSeconds > 0
            ? Duration(milliseconds: (_offsetSeconds * 1000).round())
            : Duration.zero;
        await _myController!.seekTo(_myTrimStart + extra);
      }
      if (hasRef) await _refController!.play();
      if (hasMy) await _myController!.play();
      _startPositionTimer();
      setState(() => _syncPlaying = true);
    }
  }

  Future<void> _rewindBoth() async {
    if (_refController?.value.isInitialized ?? false) {
      await _refController!.pause();
      await _refController!.seekTo(_refTrimStart);
    }
    if (_myController?.value.isInitialized ?? false) {
      await _myController!.pause();
      await _myController!.seekTo(_myTrimStart);
    }
    _stopPositionTimer();
    setState(() => _syncPlaying = false);
  }

  Future<void> _seekBoth(int deltaSeconds) async {
    if (_refController != null) {
      final pos = await _refController!.position ?? Duration.zero;
      await _refController!.seekTo(pos + Duration(seconds: deltaSeconds));
    }
    if (_myController != null) {
      final pos = await _myController!.position ?? Duration.zero;
      await _myController!.seekTo(pos + Duration(seconds: deltaSeconds));
    }
    if (mounted) setState(() {});
  }

  Future<void> _seekToTime(double seconds) async {
    final refTime = seconds;
    final myTime = seconds - _offsetSeconds;
    if (_refController?.value.isInitialized ?? false) {
      final clamped = refTime.clamp(0.0, _refDuration);
      await _refController!
          .seekTo(Duration(milliseconds: (clamped * 1000).round()));
    }
    if (_myController?.value.isInitialized ?? false) {
      final clamped = myTime.clamp(0.0, _myDuration);
      await _myController!
          .seekTo(Duration(milliseconds: (clamped * 1000).round()));
    }
    if (mounted) setState(() {});
  }

  bool get _isAnyLandscape {
    if (_refController?.value.isInitialized == true &&
        _refController!.value.aspectRatio > 1.0) {
      return true;
    }
    if (_myController?.value.isInitialized == true &&
        _myController!.value.aspectRatio > 1.0) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(compareModeProvider);
    final selectedRefId = ref.watch(selectedRefIdProvider);
    final selectedMyVideoId = ref.watch(selectedMyVideoIdProvider);
    final visibleRefs = ref.watch(visibleReferencesProvider);
    final allMyVideos = ref.watch(visibleMyVideosProvider);

    if (selectedRefId == null && visibleRefs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedRefIdProvider.notifier).state = visibleRefs.first.id;
      });
    }

    final currentRef =
        visibleRefs.where((r) => r.id == selectedRefId).firstOrNull;
    final myVideosForRef = currentRef != null
        ? allMyVideos.where((v) => v.refId == currentRef.id).toList()
        : <MyVideo>[];
    final selectedMyVideo =
        allMyVideos.where((v) => v.id == selectedMyVideoId).firstOrNull;

    _autoLoadVideos(currentRef, selectedMyVideo);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          mode == CompareMode.comparison ? '比較' : '自分の動画',
          style: const TextStyle(color: AppColors.text),
        ),
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            ref.read(compareModeProvider.notifier).state =
                mode == CompareMode.comparison
                    ? CompareMode.single
                    : CompareMode.comparison;
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                mode == CompareMode.comparison
                    ? CupertinoIcons.videocam
                    : CupertinoIcons.play_rectangle,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 4),
              Text(
                mode == CompareMode.comparison ? '単体再生' : '比較モード',
                style: const TextStyle(fontSize: 12, color: AppColors.accent),
              ),
            ],
          ),
        ),
      ),
      child: SafeArea(
        child: mode == CompareMode.comparison
            ? _buildComparisonMode(
                currentRef, myVideosForRef, selectedMyVideo, visibleRefs)
            : _buildSingleMode(selectedMyVideo, allMyVideos, visibleRefs),
      ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration:
                  BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textSub, fontSize: 14)),
            const SizedBox(height: 24),
            CupertinoButton(
              color: AppColors.accent.withValues(alpha: 0.15),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              borderRadius: BorderRadius.circular(10),
              onPressed: onPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.add, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(buttonLabel,
                      style: const TextStyle(color: AppColors.accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // ── Comparison Mode ──
  // ══════════════════════════════════════════
  Widget _buildComparisonMode(
    dynamic currentRef,
    List<MyVideo> myVideosForRef,
    MyVideo? selectedMyVideo,
    List<dynamic> visibleRefs,
  ) {
    if (visibleRefs.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.play_rectangle,
        iconColor: AppColors.accent,
        bgColor: AppColors.accentDim,
        title: '比較する動画がありません',
        description: 'まず「見本動画」タブから\n見本動画を追加してください。\nその後、自分の動画を撮影して比較できます。',
        buttonLabel: '見本動画を追加',
        onPressed: () => ref.read(selectedTabProvider.notifier).state = 1,
      );
    }

    final isLandscape = _isAnyLandscape;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRefSelector(visibleRefs, currentRef),
          const SizedBox(height: 12),
          if (isLandscape)
            Column(
              children: [
                _buildVideoPanel(
                  label: '見本',
                  color: AppColors.refAccent,
                  bgColor: AppColors.refBg,
                  controller: _refController,
                  mirror: currentRef?.mirror ?? false,
                  showTrimIcon: _refShowTrimIcon,
                  onTapVideo: () =>
                      setState(() => _refShowTrimIcon = !_refShowTrimIcon),
                  onTapTrimIcon: () => _showTrimSheet(context, isRef: true),
                  onTapEmpty: () => _showRefPicker(visibleRefs),
                  trimStart: _refTrimStart,
                  trimEnd: _refTrimEnd,
                ),
                const SizedBox(height: 8),
                _buildVideoPanel(
                  label: '自分',
                  color: AppColors.myAccent,
                  bgColor: AppColors.myBg,
                  controller: _myController,
                  showTrimIcon: _myShowTrimIcon,
                  onTapVideo: () =>
                      setState(() => _myShowTrimIcon = !_myShowTrimIcon),
                  onTapTrimIcon: () => _showTrimSheet(context, isRef: false),
                  onTapEmpty: () => _addMyVideo(),
                  trimStart: _myTrimStart,
                  trimEnd: _myTrimEnd,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _buildVideoPanel(
                  label: '見本',
                  color: AppColors.refAccent,
                  bgColor: AppColors.refBg,
                  controller: _refController,
                  mirror: currentRef?.mirror ?? false,
                  showTrimIcon: _refShowTrimIcon,
                  onTapVideo: () =>
                      setState(() => _refShowTrimIcon = !_refShowTrimIcon),
                  onTapTrimIcon: () => _showTrimSheet(context, isRef: true),
                  onTapEmpty: () => _showRefPicker(visibleRefs),
                  trimStart: _refTrimStart,
                  trimEnd: _refTrimEnd,
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildVideoPanel(
                  label: '自分',
                  color: AppColors.myAccent,
                  bgColor: AppColors.myBg,
                  controller: _myController,
                  showTrimIcon: _myShowTrimIcon,
                  onTapVideo: () =>
                      setState(() => _myShowTrimIcon = !_myShowTrimIcon),
                  onTapTrimIcon: () => _showTrimSheet(context, isRef: false),
                  onTapEmpty: () => _addMyVideo(),
                  trimStart: _myTrimStart,
                  trimEnd: _myTrimEnd,
                )),
              ],
            ),
          const SizedBox(height: 12),
          // ── Timeline ──
          _buildTimeline(),
          const SizedBox(height: 10),
          // ── Unified Controls ──
          _buildUnifiedControls(),
          const SizedBox(height: 12),
          if (currentRef != null && currentRef.memo.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('メモ',
                      style:
                          TextStyle(color: AppColors.textSub, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(currentRef.memo,
                      style: const TextStyle(
                          color: AppColors.text, fontSize: 14)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          _buildMyVideoThumbnails(myVideosForRef, selectedMyVideo),
        ],
      ),
    );
  }

  Future<void> _addMyVideo() async {
    final refId = ref.read(selectedRefIdProvider);
    if (refId == null) return;
    final path = await showVideoAddModal(context);
    if (path != null) {
      final mv = await ref.read(myVideosProvider.notifier).add(
            label:
                '練習${ref.read(myVideosForRefProvider(refId)).length + 1}',
            refId: refId,
            videoPath: path,
          );
      ref.read(selectedMyVideoIdProvider.notifier).state = mv.id;
      _initMyVideo(path);
    }
  }

  Widget _buildRefSelector(List<dynamic> visibleRefs, dynamic currentRef) {
    return GestureDetector(
      onTap: () => _showRefPicker(visibleRefs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.film,
                size: 18, color: AppColors.refAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                currentRef != null ? '${currentRef.title}' : '見本動画を選択',
                style: TextStyle(
                  color:
                      currentRef != null ? AppColors.text : AppColors.textSub,
                  fontSize: 15,
                ),
              ),
            ),
            if (currentRef != null)
              Text(
                '${ref.read(visibleMyVideosProvider).where((v) => v.refId == currentRef.id).length}本',
                style:
                    const TextStyle(color: AppColors.textSub, fontSize: 13),
              ),
            const SizedBox(width: 6),
            const Icon(CupertinoIcons.chevron_down,
                size: 14, color: AppColors.textSub),
          ],
        ),
      ),
    );
  }

  void _showRefPicker(List<dynamic> visibleRefs) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('見本動画を選択'),
        actions: visibleRefs.map((r) {
          final count = ref
              .read(visibleMyVideosProvider)
              .where((v) => v.refId == r.id)
              .length;
          return CupertinoActionSheetAction(
            onPressed: () {
              ref.read(selectedRefIdProvider.notifier).state = r.id as String;
              Navigator.pop(ctx);
            },
            child: Text('${r.title} ($count本)'),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  // ── Video Panel (comparison mode: no individual controls) ──
  Widget _buildVideoPanel({
    required String label,
    required Color color,
    required Color bgColor,
    VideoPlayerController? controller,
    bool mirror = false,
    required bool showTrimIcon,
    required VoidCallback onTapVideo,
    required VoidCallback onTapTrimIcon,
    required VoidCallback onTapEmpty,
    Duration trimStart = Duration.zero,
    Duration? trimEnd,
  }) {
    final initialized = controller?.value.isInitialized ?? false;
    final videoAR = initialized ? controller!.value.aspectRatio : 9 / 16;
    final hasTrim = trimStart > Duration.zero || trimEnd != null;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: videoAR,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: initialized
                ? GestureDetector(
                    onTap: onTapVideo,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: controller!.value.size.width,
                                height: controller.value.size.height,
                                child: Transform.flip(
                                  flipX: mirror,
                                  child: VideoPlayer(controller),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (showTrimIcon)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: onTapTrimIcon,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.bg.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(CupertinoIcons.crop,
                                    color: AppColors.accent, size: 20),
                              ),
                            ),
                          ),
                        if (hasTrim)
                          Positioned(
                            bottom: 6,
                            left: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.bg.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_fmtDur(trimStart)} - ${_fmtDur(trimEnd ?? controller.value.duration)}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: color, fontSize: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: onTapEmpty,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.play_circle,
                              size: 40,
                              color: color.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text('タップして選択',
                              style: TextStyle(
                                  color: color.withValues(alpha: 0.5),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  // ══════════════════════════════════════════
  // ── Timeline (dual-track) ──
  // ══════════════════════════════════════════
  Widget _buildTimeline() {
    const double trackH = 24;
    const double gap = 6;
    const double labelH = 16;
    const double totalH = trackH * 2 + gap + labelH + 4;

    final hasAnyVideo =
        (_refController?.value.isInitialized ?? false) ||
        (_myController?.value.isInitialized ?? false);
    if (!hasAnyVideo) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('タイムライン',
              style: TextStyle(color: AppColors.textSub, fontSize: 11)),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return GestureDetector(
                onTapDown: (d) {
                  final time =
                      _timelineStart + (d.localPosition.dx / w) * _timelineRange;
                  _seekToTime(time);
                },
                onPanStart: (d) {
                  // If touch is in the my-track area, drag to adjust offset
                  _isDraggingOffset =
                      d.localPosition.dy > trackH + gap / 2 &&
                      d.localPosition.dy < trackH * 2 + gap;
                },
                onPanUpdate: (d) {
                  if (_isDraggingOffset) {
                    final deltaSec = d.delta.dx / w * _timelineRange;
                    setState(() => _offsetSeconds += deltaSec);
                  } else {
                    final time = _timelineStart +
                        (d.localPosition.dx / w) * _timelineRange;
                    _seekToTime(time);
                  }
                },
                child: SizedBox(
                  height: totalH,
                  width: w,
                  child: CustomPaint(
                    painter: _TimelinePainter(
                      refDuration: _refDuration,
                      myDuration: _myDuration,
                      offset: _offsetSeconds,
                      refPosition: _refPosition,
                      myPosition: _myPosition,
                      refTrimStartSec:
                          _refTrimStart.inMilliseconds / 1000.0,
                      refTrimEndSec: _refTrimEnd != null
                          ? _refTrimEnd!.inMilliseconds / 1000.0
                          : _refDuration,
                      myTrimStartSec:
                          _myTrimStart.inMilliseconds / 1000.0,
                      myTrimEndSec: _myTrimEnd != null
                          ? _myTrimEnd!.inMilliseconds / 1000.0
                          : _myDuration,
                      timelineStart: _timelineStart,
                      timelineRange: _timelineRange,
                      trackH: trackH,
                      gap: gap,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          // Offset indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.arrow_right_arrow_left,
                  size: 12, color: AppColors.textDim),
              const SizedBox(width: 4),
              Text(
                'オフセット: ${_offsetSeconds.toStringAsFixed(1)}s',
                style: const TextStyle(
                    color: AppColors.textDim, fontSize: 11),
              ),
              if (_offsetSeconds != 0) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _offsetSeconds = 0),
                  child: const Text('リセット',
                      style:
                          TextStyle(color: AppColors.accent, fontSize: 11)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Unified Controls ──
  Widget _buildUnifiedControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Speed toggle
          GestureDetector(
            onTap: _cycleSpeed,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${_speed}x',
                  style: const TextStyle(
                      color: AppColors.accent, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          // Rewind to start
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: _rewindBoth,
            child: const Icon(CupertinoIcons.backward_end_fill,
                color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 10),
          // -5s
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () => _seekBoth(-5),
            child: const Icon(CupertinoIcons.backward_fill,
                color: AppColors.accent, size: 26),
          ),
          const SizedBox(width: 14),
          // Play / Pause
          GestureDetector(
            onTap: _syncPlay,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _syncPlaying
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
                color: AppColors.bg,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // +5s
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () => _seekBoth(5),
            child: const Icon(CupertinoIcons.forward_fill,
                color: AppColors.accent, size: 26),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildMyVideoThumbnails(
      List<MyVideo> myVideosForRef, MyVideo? selectedMyVideo) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _addMyVideo,
            child: Container(
              width: 64,
              height: 72,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent, width: 0.5),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add,
                      color: AppColors.accent, size: 22),
                  Text('追加',
                      style:
                          TextStyle(color: AppColors.accent, fontSize: 10)),
                ],
              ),
            ),
          ),
          ...myVideosForRef.map((v) {
            final selected = v.id == selectedMyVideo?.id;
            return GestureDetector(
              onTap: () {
                ref.read(selectedMyVideoIdProvider.notifier).state = v.id;
                _initMyVideo(v.videoPath);
              },
              child: Container(
                width: 64,
                height: 72,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.myBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.myAccent : AppColors.border,
                    width: selected ? 2 : 0.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.videocam,
                        color: AppColors.myAccent, size: 20),
                    const SizedBox(height: 4),
                    Text(v.label,
                        style: const TextStyle(
                            color: AppColors.text, fontSize: 10),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ── Single Playback Mode ──
  // ══════════════════════════════════════════
  Widget _buildSingleMode(
    MyVideo? selectedMyVideo,
    List<MyVideo> allMyVideos,
    List<dynamic> visibleRefs,
  ) {
    if (allMyVideos.isEmpty) {
      final hasRefs = visibleRefs.isNotEmpty;
      return _buildEmptyState(
        icon: CupertinoIcons.videocam,
        iconColor: AppColors.myAccent,
        bgColor: AppColors.myBg,
        title: '再生する動画がありません',
        description: hasRefs
            ? '見本動画タブから見本を選んで、\n比較画面で自分の動画を撮影・追加しましょう。'
            : 'まず「見本動画」タブから\n見本動画を追加してください。',
        buttonLabel: hasRefs ? '見本動画を見る' : '見本動画を追加',
        onPressed: () => ref.read(selectedTabProvider.notifier).state = 1,
      );
    }

    final initialized =
        _myController != null && _myController!.value.isInitialized;
    final videoAR = initialized ? _myController!.value.aspectRatio : 16 / 9;
    final hasTrim = _myTrimStart > Duration.zero || _myTrimEnd != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: videoAR,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.myBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: initialized
                  ? GestureDetector(
                      onTap: () => setState(
                          () => _myShowTrimIcon = !_myShowTrimIcon),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: _myController!.value.size.width,
                                  height: _myController!.value.size.height,
                                  child: VideoPlayer(_myController!),
                                ),
                              ),
                            ),
                          ),
                          if (_myShowTrimIcon)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _showTrimSheet(context,
                                    isRef: false),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.bg.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(CupertinoIcons.crop,
                                      color: AppColors.accent, size: 22),
                                ),
                              ),
                            ),
                          if (hasTrim)
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.bg.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_fmtDur(_myTrimStart)} - ${_fmtDur(_myTrimEnd ?? _myController!.value.duration)}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppColors.myAccent,
                                      fontSize: 11),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        if (selectedMyVideo == null &&
                            allMyVideos.isNotEmpty) {
                          final v = allMyVideos.first;
                          ref
                              .read(selectedMyVideoIdProvider.notifier)
                              .state = v.id;
                          _initMyVideo(v.videoPath);
                        }
                      },
                      child: Center(
                        child: selectedMyVideo == null
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.play_circle,
                                      size: 48,
                                      color: AppColors.myAccent
                                          .withValues(alpha: 0.5)),
                                  const SizedBox(height: 8),
                                  Text('タップして選択',
                                      style: TextStyle(
                                          color: AppColors.myAccent
                                              .withValues(alpha: 0.5),
                                          fontSize: 12)),
                                ],
                              )
                            : const Icon(CupertinoIcons.play_circle,
                                size: 48, color: AppColors.myAccent),
                      ),
                    ),
            ),
          ),
          if (selectedMyVideo != null) ...[
            const SizedBox(height: 8),
            Text(selectedMyVideo.label,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            Text(
              '${selectedMyVideo.date}  ·  ${_getRefTitle(selectedMyVideo.refId, visibleRefs)}',
              style:
                  const TextStyle(color: AppColors.textSub, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _cycleSpeed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.myAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${_speed}x',
                        style: const TextStyle(
                            color: AppColors.myAccent, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 16),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    if (_myController == null) return;
                    final pos =
                        await _myController!.position ?? Duration.zero;
                    await _myController!
                        .seekTo(pos - const Duration(seconds: 5));
                  },
                  child: const Icon(CupertinoIcons.backward_fill,
                      color: AppColors.myAccent, size: 28),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_myController == null) return;
                    _myController!.setPlaybackSpeed(_speed);
                    setState(() {
                      _myController!.value.isPlaying
                          ? _myController!.pause()
                          : _myController!.play();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.myAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _myController != null &&
                              _myController!.value.isPlaying
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      color: AppColors.bg,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    if (_myController == null) return;
                    final pos =
                        await _myController!.position ?? Duration.zero;
                    await _myController!
                        .seekTo(pos + const Duration(seconds: 5));
                  },
                  child: const Icon(CupertinoIcons.forward_fill,
                      color: AppColors.myAccent, size: 28),
                ),
                const SizedBox(width: 16),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _myController?.setLooping(
                        !(_myController?.value.isLooping ?? false));
                    setState(() {});
                  },
                  child: Icon(CupertinoIcons.repeat,
                      size: 22,
                      color: _myController?.value.isLooping ?? false
                          ? AppColors.myAccent
                          : AppColors.textSub),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSingleModeVideoList(
              allMyVideos, visibleRefs, selectedMyVideo),
        ],
      ),
    );
  }

  Widget _buildSingleModeVideoList(
    List<MyVideo> allMyVideos,
    List<dynamic> visibleRefs,
    MyVideo? selectedMyVideo,
  ) {
    final Map<String, List<MyVideo>> groups = {};
    for (final v in allMyVideos) {
      groups.putIfAbsent(v.refId, () => []).add(v);
    }
    return Column(
      children: groups.entries.map((e) {
        final refTitle = _getRefTitle(e.key, visibleRefs);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(refTitle,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
            ...e.value.map((v) {
              final selected = v.id == selectedMyVideo?.id;
              return GestureDetector(
                onTap: () {
                  ref.read(selectedMyVideoIdProvider.notifier).state = v.id;
                  _initMyVideo(v.videoPath);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.myBg : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          selected ? AppColors.myAccent : AppColors.border,
                      width: selected ? 1 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.myBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(CupertinoIcons.videocam,
                            color: AppColors.myAccent, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.label,
                                style: const TextStyle(
                                    color: AppColors.text, fontSize: 13)),
                            Text(v.date,
                                style: const TextStyle(
                                    color: AppColors.textSub,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(CupertinoIcons.play_fill,
                            color: AppColors.myAccent, size: 18),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  // ── Trim Sheet ──
  void _showTrimSheet(BuildContext context, {required bool isRef}) {
    final controller = isRef ? _refController : _myController;
    if (controller == null || !controller.value.isInitialized) return;

    final duration = controller.value.duration;
    var start = isRef ? _refTrimStart : _myTrimStart;
    var end = isRef ? (_refTrimEnd ?? duration) : (_myTrimEnd ?? duration);

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(16)),
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
                  const SizedBox(height: 16),
                  Text(
                    isRef ? '見本動画トリミング' : '自分の動画トリミング',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    const Text('開始',
                        style: TextStyle(
                            color: AppColors.textSub, fontSize: 14)),
                    const Spacer(),
                    Text(_fmtDur(start),
                        style: const TextStyle(
                            color: AppColors.accent, fontSize: 14)),
                  ]),
                  const SizedBox(height: 4),
                  CupertinoSlider(
                    value: start.inMilliseconds
                        .toDouble()
                        .clamp(0, end.inMilliseconds.toDouble()),
                    min: 0,
                    max: end.inMilliseconds
                        .toDouble()
                        .clamp(1, double.infinity),
                    activeColor: AppColors.accent,
                    onChanged: (v) {
                      setSheetState(() =>
                          start = Duration(milliseconds: v.round()));
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Text('終了',
                        style: TextStyle(
                            color: AppColors.textSub, fontSize: 14)),
                    const Spacer(),
                    Text(_fmtDur(end),
                        style: const TextStyle(
                            color: AppColors.accent, fontSize: 14)),
                  ]),
                  const SizedBox(height: 4),
                  CupertinoSlider(
                    value: end.inMilliseconds.toDouble().clamp(
                        start.inMilliseconds.toDouble(),
                        duration.inMilliseconds.toDouble()),
                    min: start.inMilliseconds
                        .toDouble()
                        .clamp(0, duration.inMilliseconds.toDouble()),
                    max: duration.inMilliseconds
                        .toDouble()
                        .clamp(1, double.infinity),
                    activeColor: AppColors.accent,
                    onChanged: (v) {
                      setSheetState(
                          () => end = Duration(milliseconds: v.round()));
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: CupertinoButton(
                        onPressed: () {
                          setSheetState(() {
                            start = Duration.zero;
                            end = duration;
                          });
                        },
                        child: const Text('リセット',
                            style: TextStyle(color: AppColors.textSub)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton.filled(
                        onPressed: () {
                          setState(() {
                            if (isRef) {
                              _refTrimStart = start;
                              _refTrimEnd =
                                  end < duration ? end : null;
                            } else {
                              _myTrimStart = start;
                              _myTrimEnd =
                                  end < duration ? end : null;
                            }
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('適用',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDur(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    final ms = (d.inMilliseconds % 1000) ~/ 100;
    return '$min:${sec.toString().padLeft(2, '0')}.$ms';
  }

  String _getRefTitle(String refId, List<dynamic> refs) {
    return refs
            .where((r) => r.id == refId)
            .map((r) => r.title as String)
            .firstOrNull ??
        '不明な見本';
  }
}

// ══════════════════════════════════════════
// ── Timeline Painter ──
// ══════════════════════════════════════════
class _TimelinePainter extends CustomPainter {
  final double refDuration;
  final double myDuration;
  final double offset;
  final double refPosition;
  final double myPosition;
  final double refTrimStartSec;
  final double refTrimEndSec;
  final double myTrimStartSec;
  final double myTrimEndSec;
  final double timelineStart;
  final double timelineRange;
  final double trackH;
  final double gap;

  _TimelinePainter({
    required this.refDuration,
    required this.myDuration,
    required this.offset,
    required this.refPosition,
    required this.myPosition,
    required this.refTrimStartSec,
    required this.refTrimEndSec,
    required this.myTrimStartSec,
    required this.myTrimEndSec,
    required this.timelineStart,
    required this.timelineRange,
    required this.trackH,
    required this.gap,
  });

  double _timeToX(double t, double w) =>
      ((t - timelineStart) / timelineRange) * w;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final r = 4.0;

    // ── Ref Track ──
    if (refDuration > 0) {
      final rx1 = _timeToX(0, w).clamp(0.0, w);
      final rx2 = _timeToX(refDuration, w).clamp(0.0, w);

      // Track background
      canvas.drawRRect(
        RRect.fromLTRBR(rx1, 0, rx2, trackH, Radius.circular(r)),
        Paint()..color = const Color(0xFF1A2A3A),
      );

      // Trim active region
      final trimX1 = _timeToX(refTrimStartSec, w).clamp(rx1, rx2);
      final trimX2 = _timeToX(refTrimEndSec, w).clamp(rx1, rx2);
      canvas.drawRRect(
        RRect.fromLTRBR(trimX1, 0, trimX2, trackH, Radius.circular(r)),
        Paint()..color = AppColors.refAccent.withValues(alpha: 0.35),
      );

      // Progress fill
      final posX = _timeToX(refPosition, w).clamp(rx1, rx2);
      canvas.drawRRect(
        RRect.fromLTRBR(rx1, 0, posX, trackH, Radius.circular(r)),
        Paint()..color = AppColors.refAccent.withValues(alpha: 0.6),
      );

      // Label
      _drawLabel(canvas, '見本', rx1 + 6, trackH / 2,
          AppColors.refAccent);
    }

    // ── My Track ──
    final myY = trackH + gap;
    if (myDuration > 0) {
      final mx1 = _timeToX(offset, w).clamp(0.0, w);
      final mx2 = _timeToX(offset + myDuration, w).clamp(0.0, w);

      // Track background
      canvas.drawRRect(
        RRect.fromLTRBR(mx1, myY, mx2, myY + trackH, Radius.circular(r)),
        Paint()..color = const Color(0xFF1A2A1A),
      );

      // Trim active region
      final trimX1 =
          _timeToX(offset + myTrimStartSec, w).clamp(mx1, mx2);
      final trimX2 =
          _timeToX(offset + myTrimEndSec, w).clamp(mx1, mx2);
      canvas.drawRRect(
        RRect.fromLTRBR(
            trimX1, myY, trimX2, myY + trackH, Radius.circular(r)),
        Paint()..color = AppColors.myAccent.withValues(alpha: 0.35),
      );

      // Progress fill
      final posX = _timeToX(offset + myPosition, w).clamp(mx1, mx2);
      canvas.drawRRect(
        RRect.fromLTRBR(mx1, myY, posX, myY + trackH, Radius.circular(r)),
        Paint()..color = AppColors.myAccent.withValues(alpha: 0.6),
      );

      // Label
      _drawLabel(
          canvas, '自分', mx1 + 6, myY + trackH / 2, AppColors.myAccent);

      // Offset drag hint (arrows on left edge)
      if (offset != 0) {
        final arrowPaint = Paint()
          ..color = AppColors.myAccent.withValues(alpha: 0.7)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        final cx = mx1;
        final cy = myY + trackH / 2;
        // small left-right arrow hint
        canvas.drawLine(
            Offset(cx - 3, cy), Offset(cx + 3, cy), arrowPaint);
        canvas.drawLine(
            Offset(cx - 3, cy), Offset(cx - 1, cy - 2), arrowPaint);
        canvas.drawLine(
            Offset(cx - 3, cy), Offset(cx - 1, cy + 2), arrowPaint);
        canvas.drawLine(
            Offset(cx + 3, cy), Offset(cx + 1, cy - 2), arrowPaint);
        canvas.drawLine(
            Offset(cx + 3, cy), Offset(cx + 1, cy + 2), arrowPaint);
      }
    }

    // ── Playhead ──
    final phX = _timeToX(refPosition, w).clamp(0.0, w);
    final phPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2;
    canvas.drawLine(Offset(phX, 0), Offset(phX, trackH * 2 + gap), phPaint);
    // Playhead dot
    canvas.drawCircle(
        Offset(phX, 0), 4, Paint()..color = AppColors.accent);

    // ── Time labels ──
    final labelY = trackH * 2 + gap + 4;
    _drawTimeLabel(canvas, _fmtSec(timelineStart), 0, labelY);
    final midTime = timelineStart + timelineRange / 2;
    _drawTimeLabel(canvas, _fmtSec(midTime), w / 2, labelY);
    _drawTimeLabel(
        canvas, _fmtSec(timelineStart + timelineRange), w, labelY,
        align: TextAlign.right);
  }

  void _drawLabel(
      Canvas canvas, String text, double x, double cy, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, cy - tp.height / 2));
  }

  void _drawTimeLabel(Canvas canvas, String text, double x, double y,
      {TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    double dx;
    if (align == TextAlign.right) {
      dx = x - tp.width;
    } else if (align == TextAlign.center) {
      dx = x - tp.width / 2;
    } else {
      dx = x;
    }
    tp.paint(canvas, Offset(dx.clamp(0, double.infinity), y));
  }

  String _fmtSec(double sec) {
    if (sec < 0) sec = 0;
    final m = sec ~/ 60;
    final s = (sec % 60).toInt();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) =>
      refPosition != oldDelegate.refPosition ||
      myPosition != oldDelegate.myPosition ||
      offset != oldDelegate.offset ||
      refDuration != oldDelegate.refDuration ||
      myDuration != oldDelegate.myDuration ||
      refTrimStartSec != oldDelegate.refTrimStartSec ||
      refTrimEndSec != oldDelegate.refTrimEndSec ||
      myTrimStartSec != oldDelegate.myTrimStartSec ||
      myTrimEndSec != oldDelegate.myTrimEndSec;
}
