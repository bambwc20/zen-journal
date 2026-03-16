import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_boilerplate/shared/widgets/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders title and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '데이터가 없습니다',
            ),
          ),
        ),
      );

      expect(find.text('데이터가 없습니다'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('renders description when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '제목',
              description: '설명 텍스트',
            ),
          ),
        ),
      );

      expect(find.text('설명 텍스트'), findsOneWidget);
    });

    testWidgets('renders action button when provided', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '제목',
              actionLabel: '추가하기',
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('추가하기'), findsOneWidget);
      await tester.tap(find.text('추가하기'));
      expect(actionCalled, isTrue);
    });
  });
}
