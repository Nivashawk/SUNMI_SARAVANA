import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sunmi_flutter_plugin_scan/bean/scan_result_bean.dart';

/// Wraps the SUNMI hardware scanner SDK.
///
/// KEY INSIGHT: The SUNMI SDK's [ScanSdk.startScan()] always does two things
/// in one call: (1) registers the MethodChannel listener AND (2) invokes the
/// native 'scanStart' command — which physically fires the laser.
///
/// There is no SDK-level API to separate these. So we bypass the SDK for
/// listener registration and wire the MethodChannel directly:
///   - On init → register MethodChannel handler only (no laser trigger)
///   - On button tap → invokeMethod('scanStart') to fire the laser
class ScannerService {
  static final ScannerService _instance = ScannerService._internal();
  factory ScannerService() => _instance;
  ScannerService._internal();

  static const _channel = MethodChannel('flutter_sunmi_scan');

  Function(String barcode)? _onResult;
  bool _isListening = false;

  /// Registers the scan result listener at startup.
  /// Does NOT fire the laser — only sets up the MethodChannel handler.
  void startListening(Function(String barcode) onResult) {
    _onResult = onResult;
    if (!_isListening) {
      _isListening = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'scanResult') {
          final raw = call.arguments as String?;
          if (raw != null && raw.isNotEmpty) {
            try {
              final List<dynamic> jsonList = json.decode(raw);
              final results = jsonList
                  .map((item) => ScanResultBean.fromJson(item))
                  .toList();
              if (results.isNotEmpty) {
                final barcode = results.first.VALUE ?? '';
                if (barcode.isNotEmpty) {
                  _onResult?.call(barcode);
                }
              }
            } catch (_) {
              // Ignore malformed scan results
            }
          }
        }
      });
    } else {
      // Update callback if called again
      _onResult = onResult;
    }
  }

  /// Fires the hardware laser to initiate a scan.
  /// Call this ONLY when the SCAN PRODUCT button is tapped.
  Future<void> triggerScan() async {
    try {
      await _channel.invokeMethod('scanStart');
    } on PlatformException catch (e) {
      // ignore — scanner may not be available
      // ignore: avoid_print
      print('[ScannerService] triggerScan error: ${e.message}');
    }
  }
}
