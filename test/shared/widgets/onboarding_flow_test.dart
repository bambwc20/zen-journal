import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_boilerplate/shared/widgets/onboarding_flow.dart';

void main() {
  final testPages = [
    const OnboardingPage(
      title: '환영합니다',
      description: '앱을 소개합니다',
      icon: Icons.star,
    ),
    const OnboardingPage(
      title: '기능 1',
      description: '첫 번째 기능입니다',
      icon: Icons.check,
    ),
    const OnboardingPage(
      title: '준비 완료',
      description: '준비가 되었습니다',
      icon: Icons.rocket_launch,
    ),
  ];

  group('OnboardingFlow', () {
    testWidgets('renders first page correctly', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlow(
            pages: testPages,
            onComplete: () => completed = true,
          ),
        ),
      );

      expect(find.text('환영합니다'), findsOneWidget);
      expect(find.text('앱을 소개합니다'), findsOneWidget);
      expect(find.text('다음'), findsOneWidget);
      expect(completed, isFalse);
    });

    testWidgets('navigates to next page on button tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlow(
            pages: testPages,
            onComplete: () {},
          ),
        ),
      );

      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      expect(find.text('기능 1'), findsOneWidget);
    });

    testWidgets('shows 시작하기 on last page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlow(
            pages: testPages,
            onComplete: () {},
          ),
        ),
      );

      // Navigate to last page
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      expect(find.text('시작하기'), findsOneWidget);
    });

    testWidgets('calls onComplete when finishing', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlow(
            pages: testPages,
            onComplete: () => completed = true,
          ),
        ),
      );

      // Navigate to last page
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      // Tap 시작하기
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('shows skip button when showSkip is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlow(
            pages: testPages,
            onComplete: () {},
            showSkip: true,
          ),
        ),
      );

      expect(find.text('건너뛰기'), findsOneWidget);
    });

    testWidgets('calls onSkip when skip button tapped', (tester) async {
      bool skipped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlow(
            pages: testPages,
            onComplete: () {},
            onSkip: () => skipped = true,
          ),
        ),
      );

      await tester.tap(find.text('건너뛰기'));
      expect(skipped, isTrue);
    });
  });
}
