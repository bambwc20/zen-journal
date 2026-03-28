import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Streams the current connectivity status.
final isOnlineProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));
});

/// A banner that appears at the top of the screen when the device is offline.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineAsync = ref.watch(isOnlineProvider);

    return onlineAsync.when(
      data: (isOnline) {
        if (isOnline) return const SizedBox.shrink();
        return MaterialBanner(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          content: const Text(
            'You are offline. Some features may be unavailable.',
          ),
          leading: const Icon(Icons.wifi_off, color: Colors.orange),
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          actions: const [SizedBox.shrink()],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
