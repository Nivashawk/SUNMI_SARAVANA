import 'dart:async';
import 'dart:typed_data';
import 'package:sunmi_flutter_plugin_printer/printer_sdk.dart';
import 'package:sunmi_flutter_plugin_printer/bean/printer.dart';
import 'package:sunmi_flutter_plugin_printer/listener/printer_listener.dart';
import 'package:sunmi_flutter_plugin_printer/listener/print_result.dart';
import 'package:sunmi_flutter_plugin_printer/style/qr_style.dart';
import 'package:sunmi_flutter_plugin_printer/style/base_style.dart';
import 'package:sunmi_flutter_plugin_printer/enum/align.dart' as printer;
import 'package:sunmi_flutter_plugin_printer/enum/error_level.dart';
import 'package:sunmi_flutter_plugin_printer/enum/status.dart';
import 'package:sunmi_flutter_plugin_printer/enum/dividing_line.dart';
import 'package:sunmi_flutter_plugin_printer/style/text_style.dart';


/// Wraps the SUNMI thermal printer SDK.
///
/// Usage pattern (from official example):
///   1. [PrinterSdk.instance.getPrinter] → receives [Printer] via [PrinterListener.onDefPrinter]
///   2. Use [Printer.lineApi] for receipt printing (QR, text, etc.)
///   3. Use [Printer.queryApi] for printer status checks
class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  Printer? _printer;
  bool _initialized = false;

  /// Discovers the device printer via [PrinterSdk.getPrinter].
  /// Must be called once before any printing or status queries.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final completer = Completer<void>();
    await PrinterSdk.instance.getPrinter(_AppPrinterListener((printer) {
      _printer = printer;
      if (!completer.isCompleted) completer.complete();
    }));
    // Give the listener a moment to fire
    await Future.any([
      completer.future,
      Future.delayed(const Duration(seconds: 3)),
    ]);
  }

  /// Returns true if the printer is ready (Status.READY).
  Future<bool> checkStatus() async {
    if (_printer == null) await initialize();
    try {
      final status = await _printer?.queryApi.getStatus();
      return status == Status.READY;
    } catch (_) {
      return false;
    }
  }

  /// Prints [data] encoded as a centred QR code, then feeds paper.
  /// Optionally prints absolute and total price tags if provided.
  /// Returns true on print success, false on any error.
  Future<bool> printQR(
    String data, {
    double absolutePrice = 0.0,
    double totalPrice = 0.0,
  }) async {
    if (_printer == null) await initialize();
    final lineApi = _printer?.lineApi;
    final commandApi = _printer?.commandApi;
    if (lineApi == null || commandApi == null) return false;

    final resultCompleter = Completer<bool>();

    try {
      // 1. Enable transaction mode so we can listen for print result
      await lineApi.enableTransMode(true);

      // 2. Init line with centred base style
      await lineApi.initLine(BaseStyle.getStyle().setAlign(printer.Align.CENTER));

      // 3. Queue the QR code with top margin via setPosY (pixels from top)
      await lineApi.printQrCode(
        data,
        QrStyle.getStyle()
            .setAlign(printer.Align.CENTER)
            .setDot(9)
            .setErrorLevel(ErrorLevel.H)
            .setPosY(60),
      );

      // 4. Print the value as text below the QR code
      await lineApi.printText(
        data,
        TextStyle.getStyle()
            .setTextSize(30)
            .enableBold(true),
      );

      // 5. If absolutePrice is specified, print the prices in the same line
      if (absolutePrice > 0.0) {
        final String priceStr = absolutePrice == absolutePrice.toInt()
            ? absolutePrice.toInt().toString()
            : absolutePrice.toStringAsFixed(2);
        final String totalStr = totalPrice.toStringAsFixed(2);
        
        await lineApi.printText(
          'Price:$priceStr Total Rs.$totalStr',
          TextStyle.getStyle()
              .setTextSize(30)
              .enableBold(true)
              .setAlign(printer.Align.LEFT),
        );
      } else {
        // Solid separator line — visual end of receipt for standard prints
        await lineApi.printDividingLine(DividingLine.SOLID, 0);
      }

      // 6. Bottom spacer — queued INSIDE the transaction so it is guaranteed
      //    to print. setTextHeightRatio(6) makes each line ~6x tall.
      //    3 such lines ≈ 15–20mm of blank paper below the separator.
      await lineApi.printText(
        ' ',
        TextStyle.getStyle().setTextHeightRatio(1),
      );

      // 7. Commit & execute — result fires via PrintResult.onResult
      await lineApi.printTrans(_AppPrintResult((code, msg) {
        resultCompleter.complete(code == 0);
      }));

      // 8. Disable transaction mode
      await lineApi.enableTransMode(false);

      // 9. autoOut() — advances paper past the print head so the QR is visible.
      await lineApi.autoOut();

    } catch (e) {
      await lineApi.enableTransMode(false);
      if (!resultCompleter.isCompleted) resultCompleter.complete(false);
    }

    // Wait for result with 10s timeout
    return Future.any([
      resultCompleter.future,
      Future.delayed(const Duration(seconds: 10), () => false),
    ]);
  }
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

/// Implements [PrinterListener] to receive the discovered [Printer] instance.
class _AppPrinterListener extends PrinterListener {
  final Function(Printer printer) onPrinter;
  _AppPrinterListener(this.onPrinter);

  @override
  void onDefPrinter(Printer printer) {
    onPrinter(printer);
  }
}

/// Implements the abstract [PrintResult] class to get print completion callback.
class _AppPrintResult extends PrintResult {
  final Function(int code, String? message) _onResultCallback;
  _AppPrintResult(this._onResultCallback);

  @override
  void onResult(int? resultCode, String? message) {
    _onResultCallback(resultCode ?? -1, message);
  }
}
