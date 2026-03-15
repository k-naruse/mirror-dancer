import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mirror_dancer/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MirrorDancerApp()));
    await tester.pump();
    expect(find.text('比較'), findsWidgets);
  });
}
