import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String barcode;
  final double absolutePrice;

  OcrResult({required this.barcode, required this.absolutePrice});

  @override
  String toString() => 'Barcode: $barcode, Price: Rs. $absolutePrice';
}

class PriceOcrService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Performs OCR on [imageFile] and returns the batch number
  /// and the selling price found on the Saravana Stores sticker label.
  ///
  /// Label format:
  ///   ┌────────────────────────────────────┐
  ///   │  SARAVANA STORES                   │
  ///   │  Rs.332                            │  ← price we want
  ///   │  ▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌       │
  ///   │  1606152827$#000006   375          │  ← barcode text under bars
  ///   └────────────────────────────────────┘
  ///
  /// Barcode string breakdown:
  ///   1606152827  = Product Batch Number (any length) ← we want this
  ///   $#          = Delimiter  (OCR often misreads '$' as S, 5, 8, Z …)
  ///   000006      = Running serial number (ignored)
  ///
  /// Extraction strategy:
  ///   '#' is the true anchor — OCR almost never garbles it.
  ///   We look one character back from '#' for the delimiter variant,
  ///   then capture every digit before it. This is length-agnostic:
  ///   if Saravana Stores ever changes the batch number length, this
  ///   code needs no update.
  Future<OcrResult?> extractLabelData(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    // ── DEBUG: dump every line that ML Kit recognised ─────────────────────
    if (kDebugMode) {
      debugPrint('[OCR] ══════════════ RAW OCR OUTPUT ══════════════');
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          debugPrint('[OCR] LINE: "${line.text.trim()}"');
        }
      }
      debugPrint('[OCR] ═════════════════════════════════════════════');
    }

    String? foundBarcode;
    double? foundPrice;

    // ── Regex catalogue ───────────────────────────────────────────────────
    //
    // [A] Preferred — #-anchor strategy (YOUR IDEA).
    //
    //     The '#' character is the reliable anchor because OCR almost never
    //     misreads it. We work backwards from '#':
    //
    //       ([\ \d]+)          ← group(1): batch digits (+ any OCR spaces)
    //       \s?                ← optional gap OCR may insert before delimiter
    //       [$Ss58Z8§]         ← the '$' delimiter in any OCR variant
    //       \s?                ← optional gap OCR may insert after delimiter
    //       #                  ← the '#' anchor
    //       \d{3,}             ← serial digits that follow (ignored)
    //
    //     After matching, we strip spaces from group(1) → clean batch number.
    //     This is fully length-agnostic: works for 10, 12, 14 … digit batches.
    final RegExp barcodeStrategyA =
        RegExp(r'([\d\s]{4,})\s?[$Ss58Z8§]\s?#\d{3,}');

    // [B] Fallback — '#' present but '$' was completely dropped by OCR.
    //     Matches digits (+ OCR spaces) directly followed by '#' + serial.
    //     Group(1) is cleaned the same way as Strategy A.
    final RegExp barcodeStrategyB =
        RegExp(r'([\d\s]{4,})\s?#\d{3,}');

    // [C] Last-resort — no '#' found at all (e.g. sticker partially obscured).
    //     Find the longest run of consecutive digits in the cleaned line.
    //     Because we have no delimiter anchor we cannot determine length,
    //     so we just return whatever digit run we find and log a warning.
    final RegExp barcodeStrategyC = RegExp(r'\d{6,}');

    // Price: "Rs.332"  "Rs. 332"  "Rs.332.00"  "Rs 332"
    //        Also handles Rs332 or rupee symbol if OCR emits it.
    final RegExp priceRegex =
        RegExp(r'(?:Rs\.?|₹)\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false);

    // Collect lines for a potential second pass.
    final List<String> allLines = [];

    for (final TextBlock block in recognizedText.blocks) {
      for (final TextLine line in block.lines) {
        final text = line.text.trim();
        allLines.add(text);

        // ── 1. Barcode: Strategy A (#-anchor with delimiter) ─────────────
        if (foundBarcode == null) {
          final m = barcodeStrategyA.firstMatch(text);
          if (m != null) {
            // Strip any OCR-injected spaces from the captured digit group.
            foundBarcode = m.group(1)!.replaceAll(RegExp(r'\s'), '');
            if (kDebugMode) {
              debugPrint(
                  '[OCR] ✅ Barcode [A] in: "$text"  →  $foundBarcode');
            }
          }
        }

        // ── 2. Price ──────────────────────────────────────────────────────
        if (foundPrice == null) {
          final m = priceRegex.firstMatch(text);
          if (m != null) {
            foundPrice = double.tryParse(m.group(1)!);
            if (kDebugMode) {
              debugPrint('[OCR] ✅ Price in: "$text"  →  Rs. $foundPrice');
            }
          }
        }
      }
    }

    // ── Second pass: Strategy B (delimiter dropped, '#' still present) ────
    // Runs when '$' was completely lost by OCR but '#' survived.
    if (foundBarcode == null) {
      if (kDebugMode) {
        debugPrint('[OCR] ⚠️  Strategy A failed — trying Strategy B (# anchor, no delimiter)…');
      }
      for (final text in allLines) {
        final m = barcodeStrategyB.firstMatch(text);
        if (m != null) {
          foundBarcode = m.group(1)!.replaceAll(RegExp(r'\s'), '');
          if (kDebugMode) {
            debugPrint(
                '[OCR] ✅ Barcode [B] from: "$text"  →  $foundBarcode');
          }
          break;
        }
      }
    }

    // ── Third pass: Strategy C (last resort — no '#' at all) ─────────────
    // Only runs when both A and B failed (e.g. sticker partially obscured).
    if (foundBarcode == null) {
      if (kDebugMode) {
        debugPrint('[OCR] ⚠️  Strategy B failed — trying Strategy C (longest digit run)…');
      }
      for (final text in allLines) {
        final cleaned = text.replaceAll(RegExp(r'[\s\-–]'), '');
        final m = barcodeStrategyC.firstMatch(cleaned);
        if (m != null) {
          foundBarcode = m.group(0)!;
          if (kDebugMode) {
            debugPrint(
                '[OCR] ⚠️  Barcode [C] from: "$text"  (cleaned: "$cleaned")  →  $foundBarcode  ← unverified length');
          }
          break;
        }
      }
    }

    // ── Summary log ───────────────────────────────────────────────────────
    if (kDebugMode) {
      debugPrint('[OCR] ── Result ──────────────────────────────────────');
      debugPrint('[OCR] Barcode : ${foundBarcode ?? "NOT FOUND ❌"}');
      debugPrint(
          '[OCR] Price   : ${foundPrice != null ? "Rs. $foundPrice" : "NOT FOUND ❌"}');
      debugPrint('[OCR] ─────────────────────────────────────────────────');
    }

    if (foundBarcode != null && foundPrice != null) {
      return OcrResult(barcode: foundBarcode!, absolutePrice: foundPrice!);
    }

    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
