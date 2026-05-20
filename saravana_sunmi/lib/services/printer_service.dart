import 'dart:async';
import 'package:sunmi_flutter_plugin_printer/printer_sdk.dart';
import 'package:sunmi_flutter_plugin_printer/bean/printer.dart';
import 'package:sunmi_flutter_plugin_printer/listener/printer_listener.dart';
import 'package:sunmi_flutter_plugin_printer/listener/print_result.dart';
import 'package:sunmi_flutter_plugin_printer/style/qr_style.dart';
import 'package:sunmi_flutter_plugin_printer/style/base_style.dart';
import 'package:sunmi_flutter_plugin_printer/enum/align.dart' as printer;
import 'package:sunmi_flutter_plugin_printer/enum/error_level.dart';
import 'package:sunmi_flutter_plugin_printer/enum/status.dart';
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
  /// Returns true on print success, false on any error.
  Future<bool> printQR(String data) async {
    if (_printer == null) await initialize();
    final lineApi = _printer?.lineApi;
    if (lineApi == null) return false;

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
            .setPosY(60), // top margin: 60px gap above the QR
      );

      // 4. Bottom margin — print a tall empty space after QR code
      await lineApi.printText(
        ' ',
        TextStyle.getStyle().setTextHeightRatio(8),
      );

      // 6. Commit & execute — result fires via PrintResult.onResult
      await lineApi.printTrans(_AppPrintResult((code, msg) {
        resultCompleter.complete(code == 0);
      }));

      // 7. Disable transaction mode
      await lineApi.enableTransMode(false);

      // 8. Feed paper
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
