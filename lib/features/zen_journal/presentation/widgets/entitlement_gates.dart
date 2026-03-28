import 'package:flutter/material.dart';

import 'package:flutter_boilerplate/core/subscription/entitlement.dart';
import 'bridge_ai_limit.dart';
import 'bridge_export.dart';

/// Convenience wrapper around [EntitlementGate] for general premium features.
///
/// Shows [child] if the user has the 'premium' entitlement.
/// Otherwise shows a default locked-feature placeholder or
/// the provided [placeholder].
class PremiumFeatureGate extends StatelessWidget {
  const PremiumFeatureGate({
    super.key,
    required this.child,
    this.placeholder,
  });

  final Widget child;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return EntitlementGate(
      entitlementId: 'premium',
      placeholder: placeholder,
      child: child,
    );
  }
}

/// Gate specifically for AI reflection features.
///
/// Shows [child] if the user has the 'premium' entitlement.
/// Otherwise shows the [BridgeAiLimit] widget which explains
/// the AI reflection limit and promotes Pro.
class AiReflectionGate extends StatelessWidget {
  const AiReflectionGate({
    super.key,
    required this.child,
    this.placeholder,
  });

  final Widget child;

  /// Custom placeholder. If null, defaults to [BridgeAiLimit].
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return EntitlementGate(
      entitlementId: 'premium',
      placeholder: placeholder ?? const BridgeAiLimit(),
      child: child,
    );
  }
}

/// Gate specifically for export features.
///
/// Shows [child] if the user has the 'premium' entitlement.
/// Otherwise shows the [BridgeExport] widget which explains
/// the export restriction and promotes Pro.
class ExportGate extends StatelessWidget {
  const ExportGate({
    super.key,
    required this.child,
    this.placeholder,
  });

  final Widget child;

  /// Custom placeholder. If null, defaults to [BridgeExport].
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return EntitlementGate(
      entitlementId: 'premium',
      placeholder: placeholder ?? const BridgeExport(),
      child: child,
    );
  }
}
