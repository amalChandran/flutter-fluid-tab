import 'package:flutter/material.dart';

void main() {
  runApp(DentAnimationWidget());
}

class DentAnimationWidget extends StatefulWidget {
  @override
  _DentAnimationWidgetState createState() => _DentAnimationWidgetState();
}

class _DentAnimationWidgetState extends State<DentAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1, end: 0).animate(_controller);
    _controller.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final dentManager = DentPointManager();
          dentManager.addDent(
              startPoint: Offset(0, screenWidth / 3),
              dentWidth: screenWidth,
              dentDepth: screenHeight / 6 * _animation.value);
          return CustomPaint(
            painter: CurvedPainter(
                dents: dentManager._dents, progress: _animation.value),
            child: SizedBox(width: double.infinity, height: 200),
          );
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class DentPointManager {
  final List<DentData> _dents = [];

  void addDent(
      {required Offset startPoint,
      required double dentWidth,
      required double dentDepth}) {
    final startPoint1 = startPoint;

    final startControlPoint1 =
        Offset(startPoint.dx + dentWidth * .25, startPoint.dy);
    final startControlPoint2 =
        Offset(startPoint.dx + dentWidth * .25, startPoint.dy + dentDepth);

    final middlePoint =
        Offset(startPoint.dx + dentWidth * .5, startPoint.dy + dentDepth);

    final endControlPoint1 =
        Offset(startPoint1.dx + dentWidth * .75, startPoint.dy + dentDepth);
    final endControlPoint2 =
        Offset(startPoint1.dx + dentWidth * .75, startPoint.dy);

    final endPoint = Offset(startPoint.dx + dentWidth, startPoint.dy);

    _dents.add(DentData(
        startPoint1,
        startControlPoint1,
        startControlPoint2,
        middlePoint,
        endControlPoint1,
        endControlPoint2,
        endPoint,
        endControlPoint1,
        endControlPoint2));
  }
}

class DentData {
  final Offset startPoint;
  final Offset startControlPoint1;
  final Offset startControlPoint2;

  final Offset middlePoint;
  final Offset middleControlPoint1;
  final Offset middleControlPoint2;

  final Offset endPoint;
  final Offset endControlPoint1;
  final Offset endControlPoint2;

  const DentData(
    this.startPoint,
    this.startControlPoint1,
    this.startControlPoint2,
    this.middlePoint,
    this.middleControlPoint1,
    this.middleControlPoint2,
    this.endPoint,
    this.endControlPoint1,
    this.endControlPoint2,
  );
}

class CurvedPainter extends CustomPainter {
  List<DentData> _dents;
  final double progress;

  CurvedPainter({required List<DentData> dents, required this.progress})
      : _dents = dents;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();

    // iterate through _dents
    for (var dent in _dents) {
      path.moveTo(dent.startPoint.dx, dent.startPoint.dy);

      // Animate control points
      final animatedStartControlPoint1 = Offset.lerp(
        dent.startPoint,
        dent.startControlPoint1,
        progress,
      )!;
      final animatedStartControlPoint2 = Offset.lerp(
        dent.startPoint,
        dent.startControlPoint2,
        progress,
      )!;
      final animatedMiddlePoint = Offset.lerp(
        Offset(dent.middlePoint.dx, dent.startPoint.dy),
        dent.middlePoint,
        progress,
      )!;

      path.cubicTo(
        animatedStartControlPoint1.dx,
        animatedStartControlPoint1.dy,
        animatedStartControlPoint2.dx,
        animatedStartControlPoint2.dy,
        animatedMiddlePoint.dx,
        animatedMiddlePoint.dy,
      );

      path.moveTo(animatedMiddlePoint.dx, animatedMiddlePoint.dy);

      final animatedEndControlPoint1 = Offset.lerp(
        dent.endPoint,
        dent.endControlPoint1,
        progress,
      )!;
      final animatedEndControlPoint2 = Offset.lerp(
        dent.endPoint,
        dent.endControlPoint2,
        progress,
      )!;

      path.cubicTo(
        animatedEndControlPoint1.dx,
        animatedEndControlPoint1.dy,
        animatedEndControlPoint2.dx,
        animatedEndControlPoint2.dy,
        dent.endPoint.dx,
        dent.endPoint.dy,
      );

      // drawDevPoints(canvas, size, dent);      if (progress > 0) {
      if (progress > 0) {
        drawDevPoints1(
            canvas,
            size,
            dent,
            animatedStartControlPoint1,
            animatedStartControlPoint2,
            animatedMiddlePoint,
            animatedEndControlPoint1,
            animatedEndControlPoint2);
      }
    }
    canvas.drawPath(path, paint);
  }

// TODO remove this after getting the animation point decider out side canvas. canvas should simple paint on the screen! no animation logic here
  void drawDevPoints1(
      Canvas canvas,
      Size size,
      DentData dent,
      Offset animatedStartControlPoint1,
      Offset animatedStartControlPoint2,
      Offset animatedMiddlePoint,
      Offset animatedEndControlPoint1,
      Offset animatedEndControlPoint2) {
    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final controlPointPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw animated control points and lines
    canvas.drawLine(dent.startPoint, animatedStartControlPoint1, linePaint);
    canvas.drawLine(
        animatedStartControlPoint1, animatedStartControlPoint2, linePaint);
    canvas.drawLine(animatedStartControlPoint2, animatedMiddlePoint, linePaint);

    canvas.drawCircle(dent.startPoint, 4, pointPaint);
    canvas.drawCircle(animatedMiddlePoint, 4, pointPaint);
    canvas.drawCircle(animatedStartControlPoint1, 2, controlPointPaint);
    canvas.drawCircle(animatedStartControlPoint2, 2, controlPointPaint);

    canvas.drawLine(animatedMiddlePoint, animatedEndControlPoint1, linePaint);
    canvas.drawLine(
        animatedEndControlPoint1, animatedEndControlPoint2, linePaint);
    canvas.drawLine(animatedEndControlPoint2, dent.endPoint, linePaint);

    canvas.drawCircle(dent.endPoint, 4, pointPaint);
    canvas.drawCircle(animatedEndControlPoint1, 2, controlPointPaint);
    canvas.drawCircle(animatedEndControlPoint2, 2, controlPointPaint);
  }

  void drawDevPoints(Canvas canvas, Size size, DentData dent) {
    // Draw control points and lines
    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Start and middle

    // Draw lines connecting control points
    canvas.drawLine(dent.startPoint, dent.startControlPoint1, linePaint);
    canvas.drawLine(
        dent.startControlPoint1, dent.startControlPoint2, linePaint);
    canvas.drawLine(dent.startControlPoint2, dent.middlePoint, linePaint);

    // Draw control points
    canvas.drawCircle(dent.startPoint, 4, pointPaint);
    canvas.drawCircle(dent.startControlPoint1, 4, pointPaint);
    canvas.drawCircle(dent.startControlPoint2, 4, pointPaint);
    canvas.drawCircle(dent.middlePoint, 4, pointPaint);

    // Middle and end

    // Draw lines connecting control points
    canvas.drawLine(dent.middlePoint, dent.middleControlPoint1, linePaint);
    canvas.drawLine(
        dent.middleControlPoint1, dent.middleControlPoint2, linePaint);
    canvas.drawLine(dent.middleControlPoint2, dent.endPoint, linePaint);

    // Draw control points
    canvas.drawCircle(dent.middlePoint, 4, pointPaint);
    canvas.drawCircle(dent.middleControlPoint1, 4, pointPaint);
    canvas.drawCircle(dent.middleControlPoint2, 4, pointPaint);
    canvas.drawCircle(dent.endPoint, 4, pointPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
