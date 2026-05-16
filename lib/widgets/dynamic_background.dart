import 'package:flutter/material.dart';
import 'dart:math' as math;

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
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
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
        Container(color: const Color(0xFF0D0D16)), // Deep Cyberpunk Background
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
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    
    // Draw moving glowing blobs using the Cyberpunk palette
    _drawBlob(canvas, size, paint, const Color(0xFF00FFD1).withOpacity(0.15), 0.2, 0.2, 250, 1.0); // Cyan Top Left
    _drawBlob(canvas, size, paint, const Color(0xFFFF003C).withOpacity(0.15), 0.8, 0.8, 300, 0.8); // Magenta Bottom Right
    _drawBlob(canvas, size, paint, const Color(0xFF1A1A2E).withOpacity(0.5), 0.5, 0.5, 400, 0.5);   // Deep Surface Middle
  }

  void _drawBlob(Canvas canvas, Size size, Paint paint, Color color, double xFactor, double yFactor, double radius, double speed) {
    paint.color = color;
    double x = size.width * xFactor + math.sin(animationValue * 2 * math.pi * speed) * 100;
    double y = size.height * yFactor + math.cos(animationValue * 2 * math.pi * speed) * 100;
    canvas.drawCircle(Offset(x, y), radius, paint);
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) => true;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFD1).withOpacity(0.03) // Very subtle cyan grid
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
