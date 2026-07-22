import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/scan_print_provider.dart';

/// Top header bar: logo + store name + printer status badge + WiFi icon.
class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});

  Future<Map<String, String?>> _getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'branch': prefs.getString('branch_name'),
      'floor': prefs.getString('floor_number'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final printerReady = context.watch<ScanPrintProvider>().printerReady;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset(
                'assets/saravana_store_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Store name and welcome details
          Expanded(
            child: FutureBuilder<Map<String, String?>>(
              future: _getConfig(),
              builder: (context, snapshot) {
                final branch = snapshot.data?['branch'];
                final floor = snapshot.data?['floor'];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'SUPER SARAVANA STORES',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    // if (branch != null && floor != null) ...[
                    //   const SizedBox(height: 2),
                    //   Text(
                    //     '$branch • Floor $floor',
                    //     style: const TextStyle(
                    //       fontSize: 10,
                    //       fontWeight: FontWeight.bold,
                    //       color: Color(0xFF512DA8),
                    //     ),
                    //   ),
                    // ],
                  ],
                );
              },
            ),
          ),
          // Printer status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: printerReady
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: printerReady
                    ? const Color(0xFF81C784)
                    : const Color(0xFFBDBDBD),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: printerReady
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  printerReady ? 'PRINTER READY' : 'PRINTER OFFLINE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: printerReady
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // WiFi icon
          // const Icon(Icons.wifi, size: 20, color: Color(0xFF1A1A2E)),
        ],
      ),
    );
  }
}
