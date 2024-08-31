import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:math';

void main() {
  runApp(MaterialApp(home: IconRowPage()));
}

class IconPosition {
  final double x;
  final double y;
  final double width;

  IconPosition(this.x, this.y, this.width);
}

class IconRowPage extends StatefulWidget {
  @override
  _IconRowPageState createState() => _IconRowPageState();
}

class _IconRowPageState extends State<IconRowPage> {
  List<GlobalKey> iconKeys = List.generate(5, (_) => GlobalKey());
  List<Offset> iconPositions = List.filled(5, Offset.zero);
  Key childKey = UniqueKey();
  GlobalKey<DentAnimationWidgetState> childGlobalKey =
      GlobalKey<DentAnimationWidgetState>();
  List<IconData> icons = [
    Icons.rocket,
    Icons.lightbulb,
    Icons.cake,
    Icons.flash_on,
    Icons.airplanemode_active,
  ];

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => getIconPositions());
  }

  void getIconPositions() {
    setState(() {
      iconPositions = iconKeys.map((key) {
        final RenderBox renderBox =
            key.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        return position + Offset(size.width / 2, size.height / 2);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double totalWidth = constraints.maxWidth;
        int iconCount = icons.length;
        double iconSpacing = 40.0; // You can adjust this value as needed
        double totalSpacing = iconSpacing * (iconCount - 1);
        double remainingWidth = totalWidth - totalSpacing;
        double iconSize = remainingWidth / iconCount;

        return Stack(
          children: [
            DentAnimationWidget(
              key: childGlobalKey,
              iconPositions: iconPositions,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                      // Notify the child
                      childGlobalKey.currentState?.onParentClick(index);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      transform: Matrix4.translationValues(
                        0,
                        selectedIndex == index ? -35 : 0,
                        0,
                      ),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          icons[index],
                          key: iconKeys[index],
                          size: 30,
                          color: selectedIndex == index
                              ? Colors.white
                              : Color.fromARGB(255, 47, 47, 47),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DentAnimationWidget extends StatefulWidget {
  late final List<Offset> iconPositions;

  DentAnimationWidget({Key? key, required this.iconPositions})
      : super(key: key);
  @override
  DentAnimationWidgetState createState() => DentAnimationWidgetState();
}

class DentAnimationWidgetState extends State<DentAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _circleController;
  late Animation<double> _circleJumpAnimation;

  int _circleStartPosition = 1;
  int _circleEndPosition = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: StifferCurve(),
    );

    _controller.value = 1.0;

    _circleController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _circleJumpAnimation = CurvedAnimation(
      parent: _circleController,
      curve: Curves.easeOutQuad,
    );

    _circleController.addStatusListener((status) {
      print("Circle animation status: $status");
    });
  }

  void onParentClick(int selection) {
    print("onParentClick selection : $selection");
    _startAnimation(selection + 1);
  }

  void _startAnimation(int endPosition) {
    print("_startAnimation : $endPosition");
    setState(() {
      _circleStartPosition = _circleEndPosition;
      _circleEndPosition = endPosition;
    });
    _circleController.forward(from: 0);

    _controller.reset();

    Future.delayed(Duration(milliseconds: 200), () {
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
        animation: Listenable.merge([_animation, _circleJumpAnimation]),
        builder: (context, child) {
          final dentManager = DentPointManager();
          dentManager.addDynamicDents(
              _circleEndPosition,
              widget.iconPositions,
              screenWidth,
              screenHeight,
              widget.iconPositions.length,
              _animation.value);

          Rect botTabRect = Rect.fromLTWH(
              0, screenHeight * .8, screenWidth, screenHeight * .2);

          return CustomPaint(
            painter: CurvedPainter(
              dents: dentManager._dents,
              circleProgress: _circleJumpAnimation.value,
              circleStartPosition:
                  widget.iconPositions[_circleStartPosition - 1],
              circleEndPosition: widget.iconPositions[
                  _circleEndPosition - 1], //dentManager.circlePoint,
              bottomTab: botTabRect,
              progress: _animation.value,
            ),
            child: SizedBox(width: double.infinity, height: double.infinity),
          );
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    _circleController.dispose();
    super.dispose();
  }
}

// class FluidCurve extends Curve {
//   @override
//   double transform(double t) {
//     // Custom equation for fluid-like motion
//     return -math.pow(math.e, -t * 5) * math.cos(t * 10) + 1;
//   }
// }

class StifferCurve extends Curve {
  @override
  double transform(double t) {
    // Adjusted equation for stiffer motion
    return -math.pow(math.e, -t * 8) * math.cos(t * 6) + 1;
  }
}

double easeDentWidth(double progress) {
  // Use a sine wave to create a smooth oscillation
  double oscillation = math.sin(progress * math.pi * 2) * 0.3;

  // Combine with a linear progression to ensure we end at 1.0
  double linear = progress;

  // Blend between oscillation and linear progression
  double blend = 1 - progress;

  return 1 + (oscillation * blend) - (0.3 * (1 - linear));
}

class DentPointManager {
  final List<DentData> _dents = [];

  void addDynamicDents(int currentSelection, List<Offset> iconPositions,
      double screenWidth, double screenHeight, int dentCount, double progress) {
    if (dentCount <= 0) return;

    double padding = 8;
    double availableWidth = screenWidth - (2 * padding);
    double dentWidth = screenWidth * 0.35;
    double dentDepth = screenHeight * 0.040;

    // Calculate total space between dents
    double totalSpacing = availableWidth - (dentWidth * dentCount);

    // Calculate individual spacing (including start and end)
    double spacing = totalSpacing / (dentCount + 1);

    for (int i = 0; i < dentCount; i++) {
      // Calculate dentCenter using the spaceEvenly logic, accounting for left padding
      double dentCenterX = iconPositions[i].dx;
      Offset dentCenter = Offset(dentCenterX, screenHeight * 0.8);
      // Offset dentCenter = iconPositions[i];
      addDent(
        dentCenter: dentCenter,
        dentWidth: dentWidth,
        dentDepth: dentDepth,
        progress: i == (currentSelection - 1) ? progress : 0.0,
      );
    }
    print("addDynamicDents currentSelection : $currentSelection");
  }

  void addDent(
      {
      // required Offset startPoint,
      required Offset dentCenter,
      required double dentWidth,
      required double dentDepth,
      required double progress}) {
    dentDepth = dentDepth * progress;
    dentWidth = dentWidth * easeDentWidth(progress); //dentWidth * progress;

    final startPoint = Offset(dentCenter.dx - dentWidth / 2, dentCenter.dy);

    final startControlPoint1 =
        Offset(dentCenter.dx - dentWidth * .14, dentCenter.dy);
    final animatedStartControlPoint1 = Offset.lerp(
      startPoint,
      startControlPoint1,
      progress,
    )!;

    final startControlPoint2 =
        Offset(dentCenter.dx - dentWidth * .26, dentCenter.dy + dentDepth);
    final animatedStartControlPoint2 = Offset.lerp(
      startControlPoint1,
      startControlPoint2,
      progress,
    )!;

    final middlePoint = Offset(dentCenter.dx, dentCenter.dy + dentDepth);
    final animatedMiddlePoint = Offset.lerp(
      Offset(middlePoint.dx, dentCenter.dy),
      middlePoint,
      progress,
    )!;

    final endControlPoint1 =
        Offset(dentCenter.dx + dentWidth * .26, dentCenter.dy + dentDepth);
    final endControlPoint2 =
        Offset(dentCenter.dx + dentWidth * .14, dentCenter.dy);
    final endPoint = Offset(dentCenter.dx + dentWidth / 2, dentCenter.dy);

    final animatedEndControlPoint1 = Offset.lerp(
      endPoint,
      endControlPoint1,
      progress,
    )!;
    final animatedEndControlPoint2 = Offset.lerp(
      endPoint,
      endControlPoint2,
      progress,
    )!;

    _dents.add(DentData(
        startPoint,
        animatedStartControlPoint1,
        animatedStartControlPoint2,
        animatedMiddlePoint,
        animatedEndControlPoint1,
        animatedEndControlPoint2,
        endPoint,
        animatedEndControlPoint1,
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
  static const isDevModeOn = false;
  late final List<DentData> _dents;
  late final double _circleProgress;
  late final Offset _circlestartPosition;
  late final Offset _circleEndPosition;
  late final Rect _bottomTab;
  final double progress;

  CurvedPainter(
      {required List<DentData> dents,
      required double circleProgress,
      required Offset circleStartPosition,
      required Offset circleEndPosition,
      required bottomTab,
      required this.progress}) {
    _dents = dents;
    _bottomTab = bottomTab;
    _circleProgress = circleProgress;
    _circlestartPosition = circleStartPosition;
    _circleEndPosition = circleEndPosition;
  }
  @override
  void paint(Canvas canvas, Size size) {
    final whiteFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Color.fromARGB(255, 255, 255, 255);

    final path = Path();
    path.moveTo(_bottomTab.left, _bottomTab.top);

    for (var dent in _dents) {
      path.moveTo(dent.startPoint.dx, dent.startPoint.dy);

      path.cubicTo(
        dent.startControlPoint1.dx,
        dent.startControlPoint1.dy,
        dent.startControlPoint2.dx,
        dent.startControlPoint2.dy,
        dent.middlePoint.dx,
        dent.middlePoint.dy,
      );

      path.cubicTo(
        dent.endControlPoint1.dx,
        dent.endControlPoint1.dy,
        dent.endControlPoint2.dx,
        dent.endControlPoint2.dy,
        dent.endPoint.dx,
        dent.endPoint.dy,
      );
    }

    path.lineTo(_bottomTab.right, _bottomTab.top);
    path.lineTo(_bottomTab.right, _bottomTab.bottom);
    path.lineTo(_bottomTab.left, _bottomTab.bottom);
    path.lineTo(_bottomTab.left, _bottomTab.top);
    path.close();

    // Create a new path for the rectangle
    final rectPath = Path()..addRect(_bottomTab);

    // Use difference to cut out the curve from the rectangle
    final finalPath = Path.combine(PathOperation.intersect, rectPath, path);

    canvas.drawPath(finalPath, whiteFillPaint);

    drawCircle(canvas, size);

    if (isDevModeOn) {
      for (var dent in _dents) {
        drawDevPoints(canvas, size, dent);
      }
    }
  }

  // Custom function for flattened sine curve
  double _flattenedSine(double x) {
    // This function creates a flatter curve compared to a regular sine
    return sin(x * pi) * (1 - x * 0.5);
  }

  void drawCircle(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pink[900]!
      ..style = PaintingStyle.fill;

    // Calculate circle position
    final startX = _circlestartPosition.dx;
    final endX = _circleEndPosition.dx;
    final x = lerpDouble(startX, endX, _circleProgress)!;

    // Calculate y position for arc
    final maxHeight = size.height * 0.1;
    final y = size.height * 0.8 - _flattenedSine(_circleProgress) * maxHeight;

    // Draw the circle
    canvas.drawCircle(Offset(x, y), 20, paint);
  }

  void drawDevPoints(Canvas canvas, Size size, DentData dent) {
    // Draw control points and lines
    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final controlPointPaint = Paint()
      ..color = Color.fromARGB(255, 146, 227, 15)
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
    canvas.drawCircle(dent.startControlPoint1, 4, controlPointPaint);
    canvas.drawCircle(dent.startControlPoint2, 4, controlPointPaint);
    canvas.drawCircle(dent.middlePoint, 4, pointPaint);

    // Middle and end

    // Draw lines connecting control points
    canvas.drawLine(dent.middlePoint, dent.middleControlPoint1, linePaint);
    canvas.drawLine(
        dent.middleControlPoint1, dent.middleControlPoint2, linePaint);
    canvas.drawLine(dent.middleControlPoint2, dent.endPoint, linePaint);

    // Draw control points
    canvas.drawCircle(dent.middlePoint, 4, pointPaint);
    canvas.drawCircle(dent.middleControlPoint1, 4, controlPointPaint);
    canvas.drawCircle(dent.middleControlPoint2, 4, controlPointPaint);
    canvas.drawCircle(dent.endPoint, 4, pointPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
