import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_print_provider.dart';

/// The "Generate & Print" CTA button.
/// Disabled when [ScanPrintProvider.canPrint] is false or while printing.
/// Shows a distinct "Printer Offline" state when the printer is not ready.
class GeneratePrintButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GeneratePrintButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScanPrintProvider>();
    final printerReady = provider.printerReady;
    final enabled = provider.canPrint && !provider.isPrinting;

    // Determine colours based on state
    final Color bgColor = !printerReady
        ? const Color(0xFFB71C1C)   // deep red — printer offline
        : enabled
            ? const Color(0xFF1976D2) // blue — ready to print
            : const Color(0xFFBDBDBD); // grey — waiting for input

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : !printerReady
                    ? [
                        BoxShadow(
                          color: const Color(0xFFB71C1C).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
          ),
          child: ElevatedButton.icon(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              disabledBackgroundColor: bgColor,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: provider.isPrinting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    !printerReady
                        ? Icons.wifi_off_rounded     // offline icon
                        : Icons.print_rounded,        // normal print icon
                    size: 22,
                  ),
            label: Text(
              provider.isPrinting
                  ? 'Printing...'
                  : !printerReady
                      ? 'Printer Offline'
                      : 'Generate & Print',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
