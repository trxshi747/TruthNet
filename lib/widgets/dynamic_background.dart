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
      duration: const Duration(seconds: 15),
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
        Container(color: const Color(0xFF312C51)), // Primary Background Color
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: BackgroundPainter(_controller.value),
              child: Container(),
            );
          },
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
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    
    // Draw moving blobs using the new palette
    _drawBlob(canvas, size, paint, const Color(0xFF48426D).withOpacity(0.4), 0.2, 0.3, 200, 1.2);
    _drawBlob(canvas, size, paint, const Color(0xFFF0C38E).withOpacity(0.15), 0.8, 0.7, 250, 0.8);
    _drawBlob(canvas, size, paint, const Color(0xFFF1AA9B).withOpacity(0.1), 0.5, 0.5, 180, 1.5);
  }

  void _drawBlob(Canvas canvas, Size size, Paint paint, Color color, double xFactor, double yFactor, double radius, double speed) {
    paint.color = color;
    double x = size.width * xFactor + math.sin(animationValue * 2 * math.pi * speed) * 80;
    double y = size.height * yFactor + math.cos(animationValue * 2 * math.pi * speed) * 80;
    canvas.drawCircle(Offset(x, y), radius, paint);
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) => true;
}
