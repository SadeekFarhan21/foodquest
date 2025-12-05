import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodQuest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CameraBarcodeScreen(),
    );
  }
}

class CameraBarcodeScreen extends StatefulWidget {
  const CameraBarcodeScreen({super.key});

  @override
  State<CameraBarcodeScreen> createState() => _CameraBarcodeScreenState();
}

class _CameraBarcodeScreenState extends State<CameraBarcodeScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  
  final TextEditingController _barcodeController = TextEditingController();
  String? _scannedBarcode;
  bool _isFlashOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture barcodeCapture) {
    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isNotEmpty) {
      final String barcodeValue = barcodes.first.rawValue ?? '';
      if (barcodeValue != _scannedBarcode) {
        setState(() {
          _scannedBarcode = barcodeValue;
          _barcodeController.text = barcodeValue;
        });
        // Show snackbar when barcode is detected
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barcode detected: $barcodeValue'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      _scannerController.toggleTorch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // First half: Camera with overlay
          Expanded(
            child: Stack(
              children: [
                // Camera preview
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onBarcodeDetect,
                ),
                // Overlay with corner brackets and scanning area
                _buildCameraOverlay(),
                // Bottom left icon (document/history)
                Positioned(
                  bottom: 24,
                  left: 24,
                  child: _buildOverlayButton(
                    icon: Icons.description_outlined,
                    onTap: () {
                      // Handle history/previous scans
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('History feature coming soon')),
                      );
                    },
                  ),
                ),
                // Bottom right icon (flashlight)
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: _buildOverlayButton(
                    icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    onTap: _toggleFlash,
                  ),
                ),
              ],
            ),
          ),
          // Second half: Barcode input
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter Barcode',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _barcodeController,
                    decoration: InputDecoration(
                      hintText: 'Scan or type barcode here',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_barcodeController.text.isNotEmpty) {
                        // Handle barcode submission
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Barcode submitted: ${_barcodeController.text}'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return CustomPaint(
      painter: ScannerOverlayPainter(),
      child: Container(),
    );
  }

  Widget _buildOverlayButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final bracketLength = 30.0;
    final bracketWidth = 30.0;
    final cornerRadius = 8.0;

    // Top-left corner bracket
    _drawCornerBracket(
      canvas,
      paint,
      Offset(bracketWidth, bracketLength),
      bracketLength,
      bracketWidth,
      cornerRadius,
      isTopLeft: true,
    );

    // Top-right corner bracket
    _drawCornerBracket(
      canvas,
      paint,
      Offset(size.width - bracketWidth, bracketLength),
      bracketLength,
      bracketWidth,
      cornerRadius,
      isTopLeft: false,
    );

    // Bottom-left corner bracket
    _drawCornerBracket(
      canvas,
      paint,
      Offset(bracketWidth, size.height - bracketLength),
      bracketLength,
      bracketWidth,
      cornerRadius,
      isTopLeft: true,
      isBottom: true,
    );

    // Bottom-right corner bracket
    _drawCornerBracket(
      canvas,
      paint,
      Offset(size.width - bracketWidth, size.height - bracketLength),
      bracketLength,
      bracketWidth,
      cornerRadius,
      isTopLeft: false,
      isBottom: true,
    );

    // Draw circular scanning area in center
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final circleRadius = size.width * 0.3;

    // Outer circle
    canvas.drawCircle(
      Offset(centerX, centerY),
      circleRadius,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Inner rectangle with barcode icon area
    final rectSize = circleRadius * 0.6;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: rectSize,
        height: rectSize * 0.6,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(
      rect,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw barcode lines inside the rectangle
    final lineCount = 8;
    final lineWidth = rectSize / (lineCount * 2);
    final startX = centerX - rectSize / 2 + lineWidth;
    
    for (int i = 0; i < lineCount; i++) {
      final x = startX + (i * lineWidth * 2);
      final lineHeight = rectSize * 0.4 * (0.5 + (i % 3) * 0.25);
      canvas.drawRect(
        Rect.fromLTWH(
          x,
          centerY - lineHeight / 2,
          lineWidth * (1 + (i % 2)),
          lineHeight,
        ),
        Paint()..color = Colors.white.withOpacity(0.8),
      );
    }
  }

  void _drawCornerBracket(
    Canvas canvas,
    Paint paint,
    Offset start,
    double length,
    double width,
    double radius,
    {required bool isTopLeft,
    bool isBottom = false,
  }) {
    final path = Path();
    
    if (isTopLeft) {
      if (isBottom) {
        // Bottom-left: L shape pointing up and right
        path.moveTo(start.dx, start.dy - length);
        path.lineTo(start.dx, start.dy - radius);
        path.quadraticBezierTo(start.dx, start.dy, start.dx + radius, start.dy);
        path.lineTo(start.dx + width, start.dy);
      } else {
        // Top-left: L shape pointing down and right
        path.moveTo(start.dx, start.dy + length);
        path.lineTo(start.dx, start.dy + radius);
        path.quadraticBezierTo(start.dx, start.dy, start.dx + radius, start.dy);
        path.lineTo(start.dx + width, start.dy);
      }
    } else {
      if (isBottom) {
        // Bottom-right: L shape pointing up and left
        path.moveTo(start.dx, start.dy - length);
        path.lineTo(start.dx, start.dy - radius);
        path.quadraticBezierTo(start.dx, start.dy, start.dx - radius, start.dy);
        path.lineTo(start.dx - width, start.dy);
      } else {
        // Top-right: L shape pointing down and left
        path.moveTo(start.dx, start.dy + length);
        path.lineTo(start.dx, start.dy + radius);
        path.quadraticBezierTo(start.dx, start.dy, start.dx - radius, start.dy);
        path.lineTo(start.dx - width, start.dy);
      }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
