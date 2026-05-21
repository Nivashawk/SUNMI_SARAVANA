import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_print_provider.dart';

/// Custom 3×4 numeric keypad widget.
/// Keys: 1–9, decimal point, 0, and backspace.
/// Fills all available vertical space via Expanded rows.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({super.key});

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ScanPrintProvider>();

    return Column(
      children: [
        for (int r = 0; r < _rows.length; r++) ...[
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int c = 0; c < _rows[r].length; c++) ...[
                  Expanded(
                    child: _KeyButton(
                      label: _rows[r][c],
                      isBackspace: _rows[r][c] == '⌫',
                      onTap: () {
                        if (_rows[r][c] == '⌫') {
                          provider.deleteDigit();
                        } else {
                          provider.appendDigit(_rows[r][c]);
                        }
                      },
                    ),
                  ),
                  if (c < _rows[r].length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          if (r < _rows.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final bool isBackspace;
  final VoidCallback onTap;

  const _KeyButton({
    required this.label,
    required this.isBackspace,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isBackspace ? const Color(0xFFF5F5F5) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isBackspace
                  ? const Color(0xFFE0E0E0)
                  : const Color(0xFFE8E8E8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isBackspace
              ? const Icon(
                  Icons.backspace_outlined,
                  color: Color(0xFFE53935),
                  size: 22,
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
        ),
      ),
    );
  }
}
