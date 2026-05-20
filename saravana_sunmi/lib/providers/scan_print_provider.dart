import 'package:flutter/foundation.dart';

class ScanPrintProvider extends ChangeNotifier {
  // ─── State ────────────────────────────────────────────────────────────────
  String _barcodeResult = '';
  String _lengthInput = '';
  bool _printerReady = false;
  bool _isPrinting = false;

  // ─── Getters ──────────────────────────────────────────────────────────────
  String get barcodeResult => _barcodeResult;
  bool get printerReady => _printerReady;
  bool get isPrinting => _isPrinting;

  /// Formats the raw digit string into a display like "0.00" or "12.50"
  String get displayLength {
    if (_lengthInput.isEmpty) return '0.00';
    // If only decimal point typed, show "0."
    if (_lengthInput == '.') return '0.';
    // If it ends with a dot, show as-is
    if (_lengthInput.endsWith('.')) return _lengthInput;
    final val = double.tryParse(_lengthInput);
    if (val == null) return '0.00';
    // Show at least 2 decimal places if decimal entered
    if (_lengthInput.contains('.')) {
      final parts = _lengthInput.split('.');
      final decimals = parts[1].length;
      return val.toStringAsFixed(decimals < 2 ? 2 : decimals);
    }
    return _lengthInput;
  }

  /// The numeric value of the entered length
  double get lengthValue {
    if (_lengthInput.isEmpty || _lengthInput == '.') return 0.0;
    return double.tryParse(_lengthInput) ?? 0.0;
  }

  /// Whether both barcode and a valid length > 0 are ready
  bool get canPrint => _barcodeResult.isNotEmpty && lengthValue > 0;

  /// Final string to be encoded as QR: "BARCODE|LENGTH"
  String get mergedResult {
    final len = lengthValue.toStringAsFixed(2);
    return '$_barcodeResult|$len';
  }

  // ─── Scanner ──────────────────────────────────────────────────────────────
  void setBarcodeResult(String barcode) {
    _barcodeResult = barcode.trim();
    notifyListeners();
  }

  void clearBarcode() {
    _barcodeResult = '';
    notifyListeners();
  }

  // ─── Numeric Keypad ───────────────────────────────────────────────────────
  void appendDigit(String digit) {
    // Handle decimal point
    if (digit == '.') {
      if (_lengthInput.contains('.')) return; // only one dot allowed
      if (_lengthInput.isEmpty) {
        _lengthInput = '0.';
      } else {
        _lengthInput += '.';
      }
      notifyListeners();
      return;
    }

    // Prevent leading double zeros e.g. "00"
    if (_lengthInput == '0' && digit == '0') return;

    // Replace leading zero before decimal
    if (_lengthInput == '0' && digit != '.') {
      _lengthInput = digit;
      notifyListeners();
      return;
    }

    // Limit decimal places to 2
    if (_lengthInput.contains('.')) {
      final parts = _lengthInput.split('.');
      if (parts[1].length >= 2) return;
    }

    _lengthInput += digit;
    notifyListeners();
  }

  void deleteDigit() {
    if (_lengthInput.isNotEmpty) {
      _lengthInput = _lengthInput.substring(0, _lengthInput.length - 1);
      notifyListeners();
    }
  }

  // ─── Printer Status ───────────────────────────────────────────────────────
  void setPrinterReady(bool ready) {
    _printerReady = ready;
    notifyListeners();
  }

  void setIsPrinting(bool printing) {
    _isPrinting = printing;
    notifyListeners();
  }

  // ─── Reset ────────────────────────────────────────────────────────────────
  /// Called after a successful print — wipes all temp state
  void reset() {
    _barcodeResult = '';
    _lengthInput = '';
    _isPrinting = false;
    notifyListeners();
  }
}
