import 'dart:math' as math;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/app_colors.dart';
import '../../shared/glass_container.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  bool _deviceSupported = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkDeviceSupport();
  }

  Future<void> _checkDeviceSupport() async {
    if (kIsWeb || Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    if (kIsWeb) {
      setState(() {
        _deviceSupported = false;
        _loading = false;
      });
      return;
    }

    try {
      final supported = await FlutterQiblah.androidDeviceSensorSupport();
      setState(() {
        _deviceSupported = supported ?? false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _deviceSupported = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Qibla Compass',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : !_deviceSupported
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      (kIsWeb || Platform.isLinux || Platform.isWindows || Platform.isMacOS)
                          ? 'The Qibla Compass is only available on mobile devices.'
                          : 'Your device does not support the compass sensor required for Qibla direction',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      child: StreamBuilder<QiblahDirection>(
                        stream: FlutterQiblah.qiblahStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.error,
                                ),
                              ),
                            );
                          }

                          final qiblahDirection = snapshot.data;
                          if (qiblahDirection == null) {
                            return Center(
                              child: Text(
                                'Loading Qibla direction...',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }

                          return _buildCompass(qiblahDirection);
                        },
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildCompass(QiblahDirection qiblahDirection) {
    final qiblaAngle = _normalizeAngle(qiblahDirection.qiblah);

    // Calculate rotations
    // dialRotation: how much to rotate the compass card so North points North
    final dialRotation = (qiblahDirection.direction * (math.pi / 180) * -1);

    // needleRotation: angle of Kaaba relative to North on the dial
    final kaabaRotation = (qiblaAngle * (math.pi / 180));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(16),
          borderRadius: 20,
          child: Column(
            children: [
              Text(
                '${qiblaAngle.toStringAsFixed(1)}°',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              Text(
                'Direction to Mecca',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          height: 320,
          width: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Target Indicator (Fixed at the top)
              Positioned(
                top: 0,
                child: Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withAlpha(
                          128,
                        ), // .withOpacity(0.5) alternatively
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),

              // Compass Dial and Kaaba Icon
              Transform.rotate(
                angle: dialRotation,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Dial
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withAlpha(25),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.accent.withAlpha(50),
                          width: 2,
                        ),
                      ),
                      child: CustomPaint(painter: CompassPainter()),
                    ),

                    // Kaaba Icon on the dial
                    Transform.rotate(
                      angle: kaabaRotation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Connection line from center to Kaaba
                          Transform.translate(
                            offset: const Offset(
                              0,
                              -65,
                            ), // Halfway between center and Kaaba
                            child: Container(
                              width: 2,
                              height: 130, // From center (0) outwards
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment
                                      .bottomCenter, // Center of compass
                                  end: Alignment.topCenter, // Towards Kaaba
                                  colors: [
                                    AppColors.accent.withAlpha(0),
                                    AppColors.accent.withAlpha(150),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // The Kaaba Icon itself
                          Transform.translate(
                            offset: const Offset(
                              0,
                              -115,
                            ), // Placed neatly on the inner ring
                            child: const _KaabaIcon(size: 32),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Central Navigation Arrow
              // This arrow is fixed, always pointing forward (relative to the device heading)
              Icon(Icons.navigation, size: 60, color: AppColors.accent),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Rotate your phone until the\narrow points to the indicator',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  double _normalizeAngle(double angle) {
    final normalized = angle % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }
}

class _KaabaIcon extends StatelessWidget {
  final double size;
  const _KaabaIcon({this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(128),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Kiswa (Gold belt)
          Positioned(
            top: size * 0.2,
            left: 0,
            right: 0,
            child: Container(
              height: size * 0.08,
              color: const Color(0xFFFFD700),
            ),
          ),
          // Door
          Positioned(
            bottom: size * 0.15,
            right: size * 0.2,
            child: Container(
              width: size * 0.12,
              height: size * 0.18,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    const directions = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < directions.length; i++) {
      final angle = (i * 90) * (math.pi / 180);
      final x = center.dx + (radius - 35) * math.sin(angle);
      final y = center.dy - (radius - 35) * math.cos(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: GoogleFonts.plusJakartaSans(
          color: directions[i] == 'N'
              ? AppColors.error
              : AppColors.textSecondary.withAlpha(150),
          fontSize: directions[i] == 'N' ? 24 : 18,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Draw tick marks
    final paint = Paint()
      ..color = AppColors.textSecondary.withAlpha(50)
      ..strokeWidth = 1.5;

    for (var i = 0; i < 360; i += 15) {
      final angle = i * (math.pi / 180);
      final isMajor = i % 90 == 0;
      final innerRadius = isMajor ? radius - 15 : radius - 10;

      final x1 = center.dx + innerRadius * math.sin(angle);
      final y1 = center.dy - innerRadius * math.cos(angle);
      final x2 = center.dx + radius * math.sin(angle);
      final y2 = center.dy - radius * math.cos(angle);

      paint.strokeWidth = isMajor ? 2.5 : 1.5;
      paint.color = isMajor
          ? AppColors.accent.withAlpha(100)
          : AppColors.textSecondary.withAlpha(50);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
