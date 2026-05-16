import 'package:flutter/material.dart';

class ClayButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isPrimary;
  final Color? color;
  final double borderRadius;

  const ClayButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.color,
    this.borderRadius = 20.0,
  }) : super(key: key);

  @override
  _ClayButtonState createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = widget.color ?? (widget.isPrimary ? colorScheme.primary : colorScheme.surface);
    final textColor = widget.isPrimary ? colorScheme.onPrimary : colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              baseColor.withOpacity(0.85),
              baseColor,
            ],
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: baseColor.withOpacity(0.4),
                    offset: const Offset(0, 8),
                    blurRadius: 16,
                  ),
                  BoxShadow(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    offset: const Offset(-4, -4),
                    blurRadius: 12,
                  ),
                ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: textColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              widget.text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
