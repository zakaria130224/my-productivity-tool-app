import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  bool _hasPermissions = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Compass'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error reading heading: ${snapshot.error}',
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.connectionState == ConnectionState.none) {
            return Center(
              child: Text(
                'Waiting for sensors...',
                style: TextStyle(color: colorScheme.secondary),
              ),
            );
          }

          double? direction = snapshot.data?.heading;

          // if direction is null, then device does not support this sensor
          // or has not granted permission
          if (direction == null) {
            return Center(
              child: Text(
                "Device does not have sensors !",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Direction Text
                Text(
                  "${direction.ceil()}°",
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _getDirectionLabel(direction),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 50),
                // Compass Widget
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: (direction * (math.pi / 180) * -1),
                      child: CustomPaint(
                        size: const Size(300, 300),
                        painter: CompassPainter(
                          primaryColor: colorScheme.primary,
                          secondaryColor: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    // Static Marker at the top
                    Positioned(
                      top: 0,
                      child: Container(
                        width: 4,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getDirectionLabel(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    if (heading >= 292.5 && heading < 337.5) return 'NW';
    return '';
  }
}

class CompassPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  CompassPainter({required this.primaryColor, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background circle
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius - 10)),
      Colors.black.withOpacity(0.1),
      10,
      true,
    );
    
    // Draw outer ring
    final ringPaint = Paint()
      ..color = secondaryColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    canvas.drawCircle(center, radius - 10, bgPaint);
    canvas.drawCircle(center, radius - 10, ringPaint);
    
    // Draw ticks
    final tickPaint = Paint()
      ..color = secondaryColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final mainTickPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 360; i += 5) {
      final isMajor = i % 90 == 0;
      final isMinor = i % 45 == 0;
      
      final tickLength = isMajor ? 20.0 : (isMinor ? 15.0 : 10.0);
      final angle = (i - 90) * math.pi / 180;
      
      final start = Offset(
        center.dx + (radius - 35) * math.cos(angle),
        center.dy + (radius - 35) * math.sin(angle),
      );
      
      final end = Offset(
        center.dx + (radius - 35 - tickLength) * math.cos(angle),
        center.dy + (radius - 35 - tickLength) * math.sin(angle),
      );

      canvas.drawLine(start, end, i % 90 == 0 ? mainTickPaint : tickPaint);
      
      // Draw cardinal directions
      if (isMajor) {
        final textPainter = TextPainter(
          textDirection: TextDirection.ltr,
        );
        
        String text = '';
        if (i == 0) text = 'N';
        if (i == 90) text = 'E';
        if (i == 180) text = 'S';
        if (i == 270) text = 'W';

        textPainter.text = TextSpan(
          text: text,
          style: TextStyle(
            color: i == 0 ? Colors.red : secondaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        );
        
        textPainter.layout();
        
        final textOffset = Offset(
          center.dx + (radius - 60) * math.cos(angle) - textPainter.width / 2,
          center.dy + (radius - 60) * math.sin(angle) - textPainter.height / 2,
        );
        
        // Save logic to prevent rotating the text along with the canvas if we were rotating the canvas (but we are rotating the whole widget so...)
        // Actually since we rotate the whole custom paint, the letters will rotate with it, which is correct for a compass needle approach or incorrect for a "heading up" approach?
        // Wait, standard digital compasses rotate the dial (the N/E/S/W moves) so the N always points North relative to the phone top.
        // My Transform.rotate rotates the whole CustomPaint by `-direction`.
        // If I face North (0 deg): rotation is 0. N is at top. Correct.
        // If I face East (90 deg): rotation is -90. The whole dial rotates -90. N moves to Left (West position relative to phone). 
        // Wait. If I face East, North should be to my Left. So N should be at 270 degrees on the phone screen.
        // 0 degrees on screen is Top. -90 degrees on screen is Left.
        // So yes, N moves to Left. Correct. 
        textPainter.paint(canvas, textOffset);
      }
    }

    // Draw Needle (Fixed to top? No, usually dial rotates, or needle rotates. 
    // Here I am rotating the whole Dial. So I should draw a fixed indicator at the top of the screen OUTSIDE the rotated part?
    // OR I can draw the needle inside but the dial is fixed? 
    // The code above rotates the CompassPainter. So the N/S/E/W will move. 
    // So I need a static indicator outside the rotation to show "Current Heading".
    
    // Actually, let's add a needle to the center that ALWAYS points N?
    // If I rotate the dial, the N letter moves to the correct position. 
    // If I want a needle that points North, I should NOT rotate the dial, but rotate the needle.
    // BUT the typical phone compass (like iOS) rotates the DIAL so the Heading is at the top.
    // So if I am facing East, 'E' should be at the top of the screen.
    // If I face East (90), rotation is -90. E (at 90 deg on dial) moves to 0 deg (Top). Correct.
    // So the dial rotates. 
    // I should draw a fixed marker at the top to indicate "Current Heading".
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
