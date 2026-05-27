import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String barcode;
  final double absolutePrice;

  OcrResult({required this.barcode, required this.absolutePrice});

  @override
  String toString() => 'Barcode: $barcode, Price: Rs. $absolutePrice';
}

class PriceOcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Performs OCR on the image and extracts the single barcode and price
  Future<OcrResult?> extractLabelData(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    String? foundBarcode;
    double? foundPrice;

    // Regular Expression definitions
    final RegExp barcodeRegex = RegExp(r'^\d{10}$'); // Matches exactly 10 digits
    final RegExp priceRegex = RegExp(r'Rs\.?\s*(\d+(?:\.\d{2})?)', caseSensitive: false);

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        final text = line.text.trim();
        
        // 1. Look for barcode (exactly 10 digits)
        if (barcodeRegex.hasMatch(text)) {
          foundBarcode = text;
        } 
        // 2. Look for price structure (e.g. "Rs. 30" or "Rs 30" -> extract "30")
        else {
          final match = priceRegex.firstMatch(text);
          if (match != null) {
            final priceStr = match.group(1);
            if (priceStr != null) {
              foundPrice = double.tryParse(priceStr);
            }
          }
        }
      }
    }

    if (foundBarcode != null && foundPrice != null) {
      return OcrResult(barcode: foundBarcode, absolutePrice: foundPrice);
    }
    
    // In case barcode and price are found but nested across blocks, return them if both exist
    if (foundBarcode != null && foundPrice != null) {
      return OcrResult(barcode: foundBarcode, absolutePrice: foundPrice);
    }
    
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
