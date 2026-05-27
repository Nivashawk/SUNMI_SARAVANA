import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/scan_print_provider.dart';
import '../services/scanner_service.dart';
import '../services/printer_service.dart';
import '../services/price_ocr_service.dart';
import '../widgets/header_bar.dart';
import '../widgets/length_display.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/generate_print_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scannerService = ScannerService();
  final _printerService = PrinterService();
  final _ocrService = PriceOcrService();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
    });
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  /// Initialize scanner listener and check printer status on startup.
  Future<void> _initServices() async {
    final provider = context.read<ScanPrintProvider>();

    // Start scanner listener (just in case they use hardware triggers)
    _scannerService.startListening((barcode) {
      if (mounted) {
        provider.setBarcodeResult(barcode);
      }
    });

    // Check printer status
    final ready = await _printerService.checkStatus();
    if (mounted) {
      provider.setPrinterReady(ready);
    }
  }

  /// Called when CAMERA OCR SCAN is tapped.
  /// Launches the camera to capture a label and auto-extracts barcode/price.
  Future<void> _onOcrScanTapped() async {
    final provider = context.read<ScanPrintProvider>();
    
    // Trigger camera capture
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      provider.setOcrProcessing(true);
      _showSnackBar('Processing label with offline OCR...', isError: false);

      final result = await _ocrService.extractLabelData(File(pickedFile.path));
      if (result != null) {
        provider.setBarcodeResult(result.barcode);
        provider.setAbsolutePrice(result.absolutePrice);
        _showSnackBar(
          'Extracted Barcode: ${result.barcode} & Price: Rs. ${result.absolutePrice.toStringAsFixed(2)}',
          isError: false,
        );
      } else {
        _showSnackBar(
          'Failed to extract barcode & price. Please ensure the label is well-lit and clear.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('OCR Error: $e', isError: true);
    } finally {
      provider.setOcrProcessing(false);
    }
  }

  /// Called when Generate & Print button is tapped.
  Future<void> _onPrintTapped() async {
    final provider = context.read<ScanPrintProvider>();

    // Validation guards
    if (provider.barcodeResult.isEmpty) {
      _showSnackBar('Please scan a product first', isError: true);
      return;
    }
    if (provider.lengthValue <= 0) {
      _showSnackBar('Length must be greater than 0', isError: true);
      return;
    }

    // Build merged QR data: "BARCODE%12.50"
    final qrData = provider.mergedResult;

    // Show printing state
    provider.setIsPrinting(true);

    // Print with the barcode, input and optional scanned price
    final success = await _printerService.printQR(
      qrData,
      absolutePrice: provider.absolutePrice,
      totalPrice: provider.totalPrice,
    );

    if (!mounted) return;

    if (success) {
      // Reset all state after successful print
      provider.reset();
      _showSnackBar('Printed successfully!', isError: false);
    } else {
      provider.setIsPrinting(false);
      _showSnackBar('Print failed. Please check the printer.', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFD32F2F) : const Color(0xFF388E3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScanPrintProvider>();
    final hasBarcode = provider.barcodeResult.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            const HeaderBar(),
            Container(height: 1, color: const Color(0xFFE0E0E0)),

            // ── Camera OCR Card or Scanned details card ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: hasBarcode
                  ? _OcrScannedDetailsCard(
                      barcode: provider.barcodeResult,
                      absolutePrice: provider.absolutePrice,
                      totalPrice: provider.totalPrice,
                      onRescan: _onOcrScanTapped,
                    )
                  : _OcrScanCard(
                      onTap: _onOcrScanTapped,
                      isProcessing: provider.isOcrProcessing,
                    ),
            ),

            const SizedBox(height: 12),

            // ── Length display ─────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LengthDisplay(),
            ),

            const SizedBox(height: 10),

            // ── Numeric keypad — fills remaining space ─────────────────────
            const Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: NumericKeypad(),
              ),
            ),

            // ── Pinned bottom bar: Generate & Print ────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: GeneratePrintButton(onPressed: _onPrintTapped),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Camera OCR Trigger Widget Card ──────────────────────────────────────────

class _OcrScanCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isProcessing;

  const _OcrScanCard({required this.onTap, required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF512DA8), Color(0xFF673AB7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF512DA8).withValues(alpha: 0.30),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Camera icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isProcessing
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CAMERA SCAN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Scan sticker to auto-extract price',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Scanned Label Unified Details Card ──────────────────────────────────────

class _OcrScannedDetailsCard extends StatelessWidget {
  final String barcode;
  final double absolutePrice;
  final double totalPrice;
  final VoidCallback onRescan;

  const _OcrScannedDetailsCard({
    required this.barcode,
    required this.absolutePrice,
    required this.totalPrice,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Re-Scan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF43A047),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SCANNED LABEL DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF43A047),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onRescan,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF512DA8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_camera_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'RE-SCAN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFFE0E0E0), height: 1, thickness: 1),
          ),

          // Barcode Display Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Barcode:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF757575),
                ),
              ),
              Text(
                barcode,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),

          // Price Details Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Absolute Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Absolute Price',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rs. ${absolutePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              
              // Total Price (Dynamic)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Price',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rs. ${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}