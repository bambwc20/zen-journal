import 'package:flutter/material.dart';

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color? iconColor;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor,
  });
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.pages,
    required this.onComplete,
    this.onSkip,
    this.showSkip = true,
  });

  final List<OnboardingPage> pages;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;
  final bool showSkip;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == widget.pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (widget.showSkip)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: widget.onSkip ?? widget.onComplete,
                  child: const Text('Skip'),
                ),
              ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemCount: widget.pages.length,
                itemBuilder: (context, index) {
                  final page = widget.pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          page.icon,
                          size: 100,
                          color: page.iconColor ??
                              Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      widget.pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: isLast
                        ? widget.onComplete
                        : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                    child: Text(isLast ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
