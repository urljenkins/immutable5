import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immutable5/shared/glass_container.dart';

void main() {
  testWidgets('GlassContainer renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.blue,
          body: Center(
            child: GlassContainer(
              width: 200,
              height: 100,
              child: Text('Glass Content'),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GlassContainer), findsOneWidget);
    expect(find.text('Glass Content'), findsOneWidget);

    // Check if BackdropFilter is present
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('GlassContainer responds to onTap', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassContainer(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(GlassContainer));
    expect(tapped, isTrue);
  });

  testWidgets('GlassContainer golden test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.blue,
          body: Center(
            child: GlassContainer(
              width: 200,
              height: 100,
              child: Center(
                child: Text(
                  'Glass Content',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // In a real environment, you would run 'flutter test --update-goldens'
    // For now, we skip this check if the golden doesn't exist to avoid failure in this environment
    // OR we just perform the expectation if we are sure it works.
    await expectLater(
      find.byType(GlassContainer),
      matchesGoldenFile('goldens/glass_container.png'),
    );
  });
}
