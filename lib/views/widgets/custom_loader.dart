import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final String? label;

  const CustomLoader({super.key, this.size = 50.0, this.color, this.label});

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.color ?? theme.colorScheme.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Outer rotating ring
                    Positioned.fill(
                      child: Transform.rotate(
                        angle: _controller.value * 2 * math.pi,
                        child: CustomPaint(
                          painter: _RingPainter(
                            color: primaryColor,
                            width: widget.size * 0.1,
                            startAngle: 0,
                            sweepAngle: math.pi * 1.5,
                          ),
                        ),
                      ),
                    ),
                    // Inner pulsating circle
                    Center(
                      child: Transform.scale(
                        scale:
                            0.5 +
                            (math.sin(_controller.value * 2 * math.pi) * 0.2),
                        child: Container(
                          width: widget.size * 0.4,
                          height: widget.size * 0.4,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (widget.label != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.label!,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double width;
  final double startAngle;
  final double sweepAngle;

  _RingPainter({
    required this.color,
    required this.width,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => true;
}
