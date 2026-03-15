import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  } catch (e) {
    debugPrint('Hive init error: $e');
  }
  runApp(const ProviderScope(child: MirrorDancerApp()));
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
