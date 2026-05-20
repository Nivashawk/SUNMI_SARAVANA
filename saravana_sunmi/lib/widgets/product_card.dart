import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_print_provider.dart';

/// Displays the scanned product barcode or a placeholder when nothing is scanned.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    final barcode = context.watch<ScanPrintProvider>().barcodeResult;
    final hasBarcode = barcode.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasBarcode ? const Color(0xFFBBDEFB) : const Color(0xFFE0E0E0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail / icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasBarcode
                  ? const Color(0xFFE3F2FD)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasBarcode ? Icons.qr_code_2 : Icons.image_not_supported_outlined,
              color: hasBarcode
                  ? const Color(0xFF1976D2)
                  : const Color(0xFF9E9E9E),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasBarcode ? 'Product Scanned' : 'No Product Scanned',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: hasBarcode
                        ? const Color(0xFF1A1A2E)
                        : const Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasBarcode ? 'SKU: $barcode' : 'SKU:  ---',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasBarcode
                        ? const Color(0xFF424242)
                        : const Color(0xFFBDBDBD),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Scanned checkmark
          if (hasBarcode)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
        ],
      ),
    );
  }
}
