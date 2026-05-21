import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_print_provider.dart';
import '../services/scanner_service.dart';
import '../services/printer_service.dart';
import '../widgets/header_bar.dart';
import '../widgets/scan_card.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
    });
  }

  /// Initialize scanner listener and check printer status on startup.
  Future<void> _initServices() async {
    final provider = context.read<ScanPrintProvider>();

    // 1. Start scanner listener — persists for the app lifetime
    _scannerService.startListening((barcode) {
      if (mounted) {
        provider.setBarcodeResult(barcode);
      }
    });

    // 2. Check printer status
    final ready = await _printerService.checkStatus();
    if (mounted) {
      provider.setPrinterReady(ready);
    }
  }

  /// Called when the SCAN PRODUCT button is tapped.
  /// Fires the hardware laser to initiate a scan.
  Future<void> _onScanTapped() async {
    await _scannerService.triggerScan();
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

    // Build merged QR data: "BARCODE|12.50"
    final qrData = provider.mergedResult;

    // Show printing state
    provider.setIsPrinting(true);

    // Print
    final success = await _printerService.printQR(qrData);

    if (!mounted) return;

    if (success) {
      // Step 9: Reset all state after successful print
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            const HeaderBar(),
            Container(height: 1, color: const Color(0xFFE0E0E0)),

            // ── Combined scan card (idle → scanned) ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ScanCard(onScanTapped: _onScanTapped),
            ),

            const SizedBox(height: 10),

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