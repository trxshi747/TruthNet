import 'package:flutter/material.dart';

class ClayCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? color;
  final double depth;

  const ClayCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24.0,
    this.color,
    this.depth = 20.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? themeColor.withOpacity(0.9) : Colors.white.withOpacity(0.9),
            themeColor,
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Outer drop shadow (bottom right)
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
            offset: Offset(depth / 2, depth / 2),
            blurRadius: depth,
          ),
          // Outer highlight (top left)
          BoxShadow(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
            offset: Offset(-depth / 2, -depth / 2),
            blurRadius: depth,
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}
