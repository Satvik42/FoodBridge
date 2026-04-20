import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge_user/screens/needs_map_screen.dart';

void main() {
  testWidgets('NeedsMapScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: NeedsMapScreen(),
    ));

    // Wait for async operations to complete if any
    await tester.pumpAndSettle();

    // Verify important UI elements
    expect(find.text('Needs Heatmap'), findsOneWidget);
    expect(find.text('Bengaluru — Priority Zones'), findsOneWidget);
    
    // Tap on the map area to see if it sets state without crashing
    await tester.tapAt(const Offset(200, 200));
    await tester.pump();
    
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
