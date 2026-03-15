import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/reference.dart';
import '../models/my_video.dart';

const _uuid = Uuid();

// ── Boxes ──
Box<Reference> get _refBox => Hive.box<Reference>('references');
Box<MyVideo> get _myBox => Hive.box<MyVideo>('myVideos');

// ── References ──
class ReferencesNotifier extends StateNotifier<List<Reference>> {
  ReferencesNotifier() : super(_refBox.values.toList());

  void _sync() => state = _refBox.values.toList();

  Future<Reference> add({
    required String title,
    String memo = '',
    required String videoPath,
  }) async {
    final ref = Reference(
      id: _uuid.v4(),
      title: title,
      memo: memo,
      videoPath: videoPath,
      createdAt: DateTime.now().toIso8601String().substring(0, 10),
    );
    await _refBox.put(ref.id, ref);
    _sync();
    return ref;
  }

  Future<void> updateMemo(String id, String memo) async {
    final ref = _refBox.get(id);
    if (ref == null) return;
    ref.memo = memo;
    await ref.save();
    _sync();
  }

  Future<void> toggleMirror(String id) async {
    final ref = _refBox.get(id);
    if (ref == null) return;
    ref.mirror = !ref.mirror;
    await ref.save();
    _sync();
  }

  Future<void> hide(String id) async {
    final ref = _refBox.get(id);
    if (ref == null) return;
    ref.hidden = true;
    await ref.save();
    // hide linked my videos
    for (final mv in _myBox.values.where((v) => v.refId == id)) {
      mv.hidden = true;
      await mv.save();
    }
    _sync();
  }

  Future<void> unhide(String id) async {
    final ref = _refBox.get(id);
    if (ref == null) return;
    ref.hidden = false;
    await ref.save();
    // unhide linked my videos
    for (final mv in _myBox.values.where((v) => v.refId == id)) {
      mv.hidden = false;
      await mv.save();
    }
    _sync();
  }

  Future<void> delete(String id) async {
    // delete linked my videos
    final linkedIds =
        _myBox.values.where((v) => v.refId == id).map((v) => v.id).toList();
    for (final mvId in linkedIds) {
      await _myBox.delete(mvId);
    }
    await _refBox.delete(id);
    _sync();
  }
}

final referencesProvider =
    StateNotifierProvider<ReferencesNotifier, List<Reference>>(
  (ref) => ReferencesNotifier(),
);

// ── MyVideos ──
class MyVideosNotifier extends StateNotifier<List<MyVideo>> {
  MyVideosNotifier() : super(_myBox.values.toList());

  void _sync() => state = _myBox.values.toList();

  Future<MyVideo> add({
    required String label,
    required String refId,
    required String videoPath,
  }) async {
    final mv = MyVideo(
      id: _uuid.v4(),
      label: label,
      refId: refId,
      date: DateTime.now().toIso8601String().substring(0, 10),
      videoPath: videoPath,
    );
    await _myBox.put(mv.id, mv);
    _sync();
    return mv;
  }

  Future<void> hide(String id) async {
    final mv = _myBox.get(id);
    if (mv == null) return;
    mv.hidden = true;
    await mv.save();
    _sync();
  }

  Future<void> unhide(String id) async {
    final mv = _myBox.get(id);
    if (mv == null) return;
    mv.hidden = false;
    await mv.save();
    _sync();
  }

  Future<void> delete(String id) async {
    await _myBox.delete(id);
    _sync();
  }
}

final myVideosProvider =
    StateNotifierProvider<MyVideosNotifier, List<MyVideo>>(
  (ref) => MyVideosNotifier(),
);

// ── Derived ──
final visibleReferencesProvider = Provider<List<Reference>>((ref) {
  return ref.watch(referencesProvider).where((r) => !r.hidden).toList();
});

final hiddenReferencesProvider = Provider<List<Reference>>((ref) {
  return ref.watch(referencesProvider).where((r) => r.hidden).toList();
});

final visibleMyVideosProvider = Provider<List<MyVideo>>((ref) {
  return ref.watch(myVideosProvider).where((v) => !v.hidden).toList();
});

final hiddenMyVideosProvider = Provider<List<MyVideo>>((ref) {
  return ref.watch(myVideosProvider).where((v) => v.hidden).toList();
});

final myVideosForRefProvider =
    Provider.family<List<MyVideo>, String>((ref, refId) {
  return ref.watch(visibleMyVideosProvider).where((v) => v.refId == refId).toList();
});

// ── Navigation State ──
final selectedTabProvider = StateProvider<int>((ref) => 0);

enum CompareMode { comparison, single }

final compareModeProvider = StateProvider<CompareMode>((ref) => CompareMode.comparison);
final selectedRefIdProvider = StateProvider<String?>((ref) => null);
final selectedMyVideoIdProvider = StateProvider<String?>((ref) => null);
