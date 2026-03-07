// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:daily_price/main.dart';

void main() {
  testWidgets('Home screen displays form', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DailyPriceApp());

    // Verify that the app title is displayed.
    expect(find.text('个人资产管理'), findsOneWidget);
    
    // Verify that the form title is displayed.
    expect(find.text('添加资产'), findsOneWidget);
    
    // Verify that the asset list title is displayed.
    expect(find.text('资产列表'), findsOneWidget);
  });
}
