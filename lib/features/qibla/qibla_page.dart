import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'dart:math' as math;

class QiblaPage extends StatefulWidget {
  const QiblaPage({Key? key,}) : super(key: key);

  @override
  _QiblaPageState createState() => _QiblaPageState();
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
    final supported = await FlutterQiblah.androidDeviceSensorSupport();
    setState(() {
      _deviceSupported = supported ?? false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla Compass'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(),)
          : !_deviceSupported
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Your device does not support the compass sensor required for Qibla direction',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16,),
                    ),
                  ),
                )
              : StreamBuilder<QiblahDirection>(
                  stream: FlutterQiblah.qiblahStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(),);
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red,),
                        ),
                      );
                    }

                    final qiblahDirection = snapshot.data;
                    if (qiblahDirection == null) {
                      return const Center(child: Text('Loading Qibla direction...',),);
                    }

                    return _buildCompass(qiblahDirection);
                  },
                ),
    );
  }

  Widget _buildCompass(QiblahDirection qiblahDirection) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${qiblahDirection.qibla.toStringAsFixed(1)}°',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold,),
        ),
        const SizedBox(height: 16),
        const Text(
          'Direction to Mecca',
          style: TextStyle(fontSize: 18, color: Colors.grey,),
        ),
        const SizedBox(height: 48),
        SizedBox(
          height: 300,
          width: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Compass background
              Transform.rotate(
                angle: (qiblahDirection.direction * (math.pi / 180) * -1),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 2,),
                  ),
                  child: CustomPaint(
                    painter: CompassPainter(),
                    size: const Size(300, 300,),
                  ),
                ),
              ),
              // Qibla needle
              Transform.rotate(
                angle: (qiblahDirection.qibla * (math.pi / 180)),
                child: const Icon(
                  Icons.navigation,
                  size: 80,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Offset from North:'),
                    Text(
                      '${qiblahDirection.offset.toStringAsFixed(1)}°',
                      style: const TextStyle(fontWeight: FontWeight.bold,),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Align the green arrow with the compass direction',
                  style: TextStyle(fontSize: 12, color: Colors.grey,),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw cardinal directions
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    const directions = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < directions.length; i++) {
      final angle = (i * 90) * (math.pi / 180);
      final x = center.dx + (radius - 30) * math.sin(angle);
      final y = center.dy - (radius - 30) * math.cos(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: directions[i] == 'N' ? Colors.red : Colors.grey,
          fontSize: 24,
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
      ..color = Colors.grey
      ..strokeWidth = 2;

    for (var i = 0; i < 360; i += 30) {
      final angle = i * (math.pi / 180);
      final x1 = center.dx + (radius - 10) * math.sin(angle);
      final y1 = center.dy - (radius - 10) * math.cos(angle);
      final x2 = center.dx + radius * math.sin(angle);
      final y2 = center.dy - radius * math.cos(angle);
      canvas.drawLine(Offset(x1, y1,), Offset(x2, y2,), paint,);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
