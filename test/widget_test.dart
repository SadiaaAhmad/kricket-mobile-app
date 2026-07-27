// This is a basic Flutter widget test.
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:kricket_pk/main.dart';

void main() {
  testWidgets('Kricket home screen loads', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const KricketApp());
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    expect(find.text('Kricket.pk'), findsWidgets);
  });
}
