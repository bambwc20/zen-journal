import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_boilerplate/shared/widgets/onboarding_flow.dart';

void main() {
  final testPages = [
    const OnboardingPage(
      title: 'Welcome',
      description: 'Let us introduce the app',
      icon: Icons.star,
    ),
    const OnboardingPage(
      title: 'Feature 1',
      description: 'This is the first feature',
      icon: Icons.check,
    ),
    const OnboardingPage(
      title: 'All Set',
      description: 'You are ready to go',
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

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Let us introduce the app'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
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

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Feature 1'), findsOneWidget);
    });

    testWidgets('shows Get Started on last page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlow(
            pages: testPages,
            onComplete: () {},
          ),
        ),
      );

      // Navigate to last page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);
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
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap Get Started
      await tester.tap(find.text('Get Started'));
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

      expect(find.text('Skip'), findsOneWidget);
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

      await tester.tap(find.text('Skip'));
      expect(skipped, isTrue);
    });
  });
}
