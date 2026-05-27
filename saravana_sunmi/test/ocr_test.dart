import 'package:flutter_test/flutter_test.dart';
import 'package:saravana_sunmi/providers/scan_print_provider.dart';

void main() {
  group('ScanPrintProvider Dynamic Calculation and Formatting Tests', () {
    test('dynamic price calculation with valid input', () {
      final provider = ScanPrintProvider();
      
      // Set absolute price to Rs. 30.00
      provider.setAbsolutePrice(30.0);
      
      // Input length: 12.50
      provider.appendDigit('1');
      provider.appendDigit('2');
      provider.appendDigit('.');
      provider.appendDigit('5');
      provider.appendDigit('0');
      
      expect(provider.lengthValue, 12.50);
      expect(provider.absolutePrice, 30.0);
      
      // Expected total price: 30.0 * 12.50 = 375.0
      expect(provider.totalPrice, 375.0);
    });

    test('dynamic price calculation with zero input', () {
      final provider = ScanPrintProvider();
      provider.setAbsolutePrice(30.0);
      
      expect(provider.lengthValue, 0.0);
      expect(provider.totalPrice, 0.0);
    });

    test('QR Code content formatting with % separator', () {
      final provider = ScanPrintProvider();
      
      provider.setBarcodeResult('1603099558');
      
      // Input length: 12.50
      provider.appendDigit('1');
      provider.appendDigit('2');
      provider.appendDigit('.');
      provider.appendDigit('5');
      provider.appendDigit('0');
      
      // Expected output format: [barcode]%[user input] -> "1603099558%12.50"
      expect(provider.mergedResult, '1603099558%12.50');
    });

    test('reset clears absolute price and ocr states', () {
      final provider = ScanPrintProvider();
      provider.setBarcodeResult('1603099558');
      provider.setAbsolutePrice(30.0);
      provider.setOcrProcessing(true);
      
      provider.reset();
      
      expect(provider.barcodeResult, '');
      expect(provider.absolutePrice, 0.0);
      expect(provider.isOcrProcessing, false);
      expect(provider.lengthValue, 0.0);
    });
  });
}
