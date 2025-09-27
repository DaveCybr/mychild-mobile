// lib/features/family/presentation/widgets/qr_scanner_widget.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';

class QRScannerWidget extends StatefulWidget {
  final Function(String familyId) onQRScanned;
  final VoidCallback onCancel;

  const QRScannerWidget({
    super.key,
    required this.onQRScanned,
    required this.onCancel,
  });

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  bool _isFlashOn = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // QR Scanner
          MobileScanner(
            controller: controller,
            onDetect: (BarcodeCapture capture) {
              if (!_isProcessing && capture.barcodes.isNotEmpty) {
                final String? code = capture.barcodes.first.rawValue;
                if (code != null) {
                  _handleQRCode(code);
                }
              }
            },
            overlayBuilder: (context, constraints) {
              return _buildScannerOverlay();
            },
          ),

          // Top overlay with instructions
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: AppConstants.defaultPadding,
                right: AppConstants.defaultPadding,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onCancel,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Scan QR Code',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 44), // Balance the close button
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Arahkan kamera ke QR code yang ditampilkan\ndi aplikasi orang tua',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Bottom overlay with controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                top: 24,
                left: AppConstants.defaultPadding,
                right: AppConstants.defaultPadding,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Flash toggle
                  IconButton(
                    onPressed: _toggleFlash,
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: _isFlashOn ? AppColors.primary : Colors.white,
                      size: 32,
                    ),
                  ),

                  // Camera switch
                  IconButton(
                    onPressed: () => controller.switchCamera(),
                    icon: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memproses QR Code...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return CustomPaint(
      painter: QrScannerOverlayPainter(
        borderColor: AppColors.primary,
        borderRadius: 12,
        borderLength: 30,
        borderWidth: 8,
        cutOutSize: 250,
      ),
    );
  }

  void _toggleFlash() async {
    await controller.toggleTorch();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _handleQRCode(String qrCode) {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Parse QR code
      // Expected format: {"family_id": "123"}
      final Map<String, dynamic> data = jsonDecode(qrCode);
      final String? familyId = data['family_id']?.toString();

      if (familyId != null && familyId.isNotEmpty) {
        widget.onQRScanned(familyId);
      } else {
        throw Exception('Invalid QR code format');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'QR Code tidak valid. Pastikan ini adalah QR code dari aplikasi parent.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// Custom painter untuk scanner overlay
class QrScannerOverlayPainter extends CustomPainter {
  const QrScannerOverlayPainter({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final cutOutWidth = cutOutSize < width ? cutOutSize : width - borderWidth;
    final cutOutHeight = cutOutSize < height
        ? cutOutSize
        : height - borderWidth;

    final cutOutRect = Rect.fromLTWH(
      (width - cutOutWidth) / 2,
      (height - cutOutHeight) / 2,
      cutOutWidth,
      cutOutHeight,
    );

    // Draw overlay background
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      )
      ..fillType = PathFillType.evenOdd;

    final overlayPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, overlayPaint);

    // Draw corner borders
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Top left corner
    path.moveTo(cutOutRect.left - borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.left, cutOutRect.top);
    path.lineTo(cutOutRect.left, cutOutRect.top - borderLength);

    // Top right corner
    path.moveTo(cutOutRect.right + borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top - borderLength);

    // Bottom right corner
    path.moveTo(cutOutRect.right + borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.right, cutOutRect.bottom);
    path.lineTo(cutOutRect.right, cutOutRect.bottom + borderLength);

    // Bottom left corner
    path.moveTo(cutOutRect.left - borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom + borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
