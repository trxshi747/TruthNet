import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:model2/core/theme/app_theme.dart';

class DynamicBackground extends StatefulWidget {
  final Widget child;
  const DynamicBackground({Key? key, required this.child}) : super(key: key);

  @override
  _DynamicBackgroundState createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6), // Faster loop
      vsync: this,
    )..repeat(reverse: true); // Repeat with reverse for smoother continuous motion
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppTheme.darkPurple), // Deep Cyberpunk Background
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: BackgroundPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
        // Cyberpunk Grid Overlay
        CustomPaint(
          painter: GridPainter(),
          size: Size.infinite,
        ),
        widget.child,
      ],
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double animationValue;
  BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80); // Slightly less blur for stronger color presence
    
    // Draw moving glowing blobs using the brand palette with increased opacity and size
    _drawBlob(canvas, size, paint, AppTheme.peach.withOpacity(0.6), 0.2, 0.3, 300, 1.2); 
    _drawBlob(canvas, size, paint, AppTheme.coral.withOpacity(0.6), 0.8, 0.7, 350, 0.9); 
    _drawBlob(canvas, size, paint, AppTheme.mediumPurple.withOpacity(0.9), 0.5, 0.5, 500, 0.6);   
  }

  void _drawBlob(Canvas canvas, Size size, Paint paint, Color color, double xFactor, double yFactor, double radius, double speed) {
    paint.color = color;
    // Increased movement multipliers for wider arcs
    double x = size.width * xFactor + math.sin(animationValue * 2 * math.pi * speed) * 250;
    double y = size.height * yFactor + math.cos(animationValue * 2 * math.pi * speed) * 250;
    canvas.drawCircle(Offset(x, y), radius, paint);
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) => true;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.peach.withOpacity(0.03) // Very subtle cyan grid
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double gridSize = 40.0;

    // Draw vertical lines
    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i <= size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
