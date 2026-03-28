import 'package:flutter/material.dart';

/// Wraps content in a centered container with a max width constraint.
/// On phones, takes full width. On tablets, constrains to [maxWidth].
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 600,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// Returns true if the screen width is >= [breakpoint] (tablet-sized).
bool isTablet(BuildContext context, {double breakpoint = 600}) {
  return MediaQuery.sizeOf(context).width >= breakpoint;
}
