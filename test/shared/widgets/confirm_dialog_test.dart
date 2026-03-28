import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_boilerplate/shared/widgets/confirm_dialog.dart';

void main() {
  group('ConfirmDialog', () {
    testWidgets('shows title and content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDialog(
              title: 'Delete this?',
              content: 'This action cannot be undone.',
            ),
          ),
        ),
      );

      expect(find.text('Delete this?'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
    });

    testWidgets('returns true on confirm', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ConfirmDialog.show(
                  context,
                  title: 'Are you sure?',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('returns false on cancel', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ConfirmDialog.show(
                  context,
                  title: 'Are you sure?',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
