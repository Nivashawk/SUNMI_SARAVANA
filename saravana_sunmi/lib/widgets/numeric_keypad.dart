import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_print_provider.dart';

/// Custom 3×4 numeric keypad widget.
/// Keys: 1–9, decimal point, 0, and backspace.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({super.key});

  static const _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '.', '0', '⌫',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ScanPrintProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (context, index) {
          final key = _keys[index];
          final isBackspace = key == '⌫';

          return _KeyButton(
            label: key,
            isBackspace: isBackspace,
            onTap: () {
              if (isBackspace) {
                provider.deleteDigit();
              } else {
                provider.appendDigit(key);
              }
            },
          );
        },
      ),
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
