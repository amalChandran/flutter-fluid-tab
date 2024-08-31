import 'package:flutter/material.dart';

void main() {
  runApp(const CircleRectangleCanvas());
}

class CircleRectanglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromARGB(255, 255, 255, 255)
      ..style = PaintingStyle.fill;

    // Draw the rectangle at the bottom of the screen
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 100, size.width, 100),
      paint,
    );

    // Draw the circle just above the rectangle
    canvas.drawCircle(
      Offset(size.width / 2, size.height - 150),
      25,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CircleRectangleCanvas extends StatelessWidget {
  const CircleRectangleCanvas({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CircleRectanglePainter(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
