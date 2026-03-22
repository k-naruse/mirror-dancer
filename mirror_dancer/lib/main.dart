import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'models/reference.dart';
import 'models/my_video.dart';
import 'theme/app_theme.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Hive.initFlutter();
    Hive.registerAdapter(ReferenceAdapter());
    Hive.registerAdapter(MyVideoAdapter());
    await Hive.openBox<Reference>('references');
    await Hive.openBox<MyVideo>('myVideos');
    await _seedTestData();
  } catch (e) {
    debugPrint('Hive init error: $e');
  }
  runApp(const ProviderScope(child: MirrorDancerApp()));
}

/// テスト用ダミー動画データを初回のみ登録する
Future<void> _seedTestData() async {
  final refBox = Hive.box<Reference>('references');
  final myBox = Hive.box<MyVideo>('myVideos');
  if (refBox.isNotEmpty) return; // 既にデータがある場合はスキップ

  const uuid = Uuid();
  final dir = await getApplicationDocumentsDirectory();
  final testDir = Directory('${dir.path}/test_videos');
  if (!testDir.existsSync()) testDir.createSync(recursive: true);

  // アセットからコピー
  Future<String> copyAsset(String name) async {
    final dest = File('${testDir.path}/$name');
    if (!dest.existsSync()) {
      final data = await rootBundle.load('assets/test/$name');
      await dest.writeAsBytes(data.buffer.asUint8List());
    }
    return dest.path;
  }

  final refPath = await copyAsset('ref_video.mp4');
  final myPath1 = await copyAsset('my_video_1.mp4');
  final myPath2 = await copyAsset('my_video_2.mp4');

  final refId = uuid.v4();
  final ref = Reference(
    id: refId,
    title: 'テスト見本動画',
    memo: 'テスト用のダミー動画です',
    videoPath: refPath,
    createdAt: '2026-03-22',
  );
  await refBox.put(ref.id, ref);

  final mv1 = MyVideo(
    id: uuid.v4(),
    label: '練習1回目',
    refId: refId,
    date: '2026-03-22',
    videoPath: myPath1,
  );
  await myBox.put(mv1.id, mv1);

  final mv2 = MyVideo(
    id: uuid.v4(),
    label: '練習2回目',
    refId: refId,
    date: '2026-03-22',
    videoPath: myPath2,
  );
  await myBox.put(mv2.id, mv2);

  debugPrint('Test data seeded: 1 reference + 2 my videos');
}

class MirrorDancerApp extends StatelessWidget {
  const MirrorDancerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'MirrorDancer',
      theme: cupertinoTheme(),
      debugShowCheckedModeBanner: false,
      home: const HomeShell(),
    );
  }
}
