import 'package:flutter/material.dart';

/// A user-friendly error screen shown when an unrecoverable error occurs.
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    super.key,
    this.error,
    this.onRetry,
  });

  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 72,
                  color: colorScheme.error.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'An unexpected error occurred.\nPlease try again.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (onRetry != null)
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
