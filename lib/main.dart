import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'models/product.dart';
import 'services/openfoodfacts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: .env file not found. Using default values.');
  }
  
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
  Product? _product;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scannerController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture barcodeCapture) async {
    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isNotEmpty) {
      final String barcodeValue = barcodes.first.rawValue ?? '';
      if (barcodeValue != _scannedBarcode) {
        setState(() {
          _scannedBarcode = barcodeValue;
          _barcodeController.text = barcodeValue;
          _isLoading = true;
          _errorMessage = null;
          _product = null;
        });
        
        // Fetch product information from OpenFoodFacts
        try {
          final product = await OpenFoodFactsService.getProductByBarcode(barcodeValue);
          setState(() {
            _isLoading = false;
            if (product != null && product.isValid) {
              _product = product;
            } else {
              _errorMessage = 'Product not found in database';
            }
          });
        } catch (e) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Error fetching product: ${e.toString()}';
          });
        }
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
                    onPressed: () async {
                      if (_barcodeController.text.isNotEmpty) {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                          _product = null;
                        });
                        
                        try {
                          final product = await OpenFoodFactsService.getProductByBarcode(_barcodeController.text);
                          setState(() {
                            _isLoading = false;
                            if (product != null && product.isValid) {
                              _product = product;
                            } else {
                              _errorMessage = 'Product not found in database';
                            }
                          });
                        } catch (e) {
                          setState(() {
                            _isLoading = false;
                            _errorMessage = 'Error fetching product: ${e.toString()}';
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Lookup Product',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Product information display
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_product != null)
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildProductInfo(_product!),
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

  Widget _buildProductInfo(Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          if (product.imageUrl != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product.imageUrl!,
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported,
                    size: 80,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Product Name
          if (product.productName != null)
            Text(
              product.productName!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          // Brand
          if (product.brand != null)
            Text(
              'Brand: ${product.brand}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          const SizedBox(height: 8),
          // Quantity
          if (product.quantity != null)
            Text(
              'Quantity: ${product.quantity}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          const SizedBox(height: 16),
          // Nutrition Grade
          if (product.nutritionGrade != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Nutrition Grade: ${product.nutritionGrade!.toUpperCase()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Nutriments
          if (product.nutriments != null && product.nutriments!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nutrition (per 100g):',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...product.nutriments!.entries
                    .where((e) => ['energy-kcal_100g', 'fat_100g', 'carbohydrates_100g', 'proteins_100g', 'sugars_100g', 'salt_100g']
                        .contains(e.key))
                    .map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatNutrientName(entry.key),
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                '${entry.value}${_getNutrientUnit(entry.key)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )),
              ],
            ),
        ],
      ),
    );
  }

  String _formatNutrientName(String key) {
    final names = {
      'energy-kcal_100g': 'Energy',
      'fat_100g': 'Fat',
      'carbohydrates_100g': 'Carbs',
      'proteins_100g': 'Protein',
      'sugars_100g': 'Sugars',
      'salt_100g': 'Salt',
    };
    return names[key] ?? key;
  }

  String _getNutrientUnit(String key) {
    if (key == 'energy-kcal_100g') return ' kcal';
    if (key == 'salt_100g') return ' g';
    return ' g';
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
