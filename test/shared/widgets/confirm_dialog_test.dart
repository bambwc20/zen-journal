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
              title: '삭제하시겠습니까?',
              content: '이 작업은 되돌릴 수 없습니다.',
            ),
          ),
        ),
      );

      expect(find.text('삭제하시겠습니까?'), findsOneWidget);
      expect(find.text('이 작업은 되돌릴 수 없습니다.'), findsOneWidget);
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
                  title: '확인?',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('확인'));
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
                  title: '확인?',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
