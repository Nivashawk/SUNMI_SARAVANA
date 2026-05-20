import 'package:sunmi_flutter_plugin_scan/scan_sdk.dart';
import 'package:sunmi_flutter_plugin_scan/bean/scan_result_bean.dart';

/// Wraps the SUNMI hardware scanner SDK.
/// The V2 Plus built-in laser scanner is accessed via [ScanSdk].
class ScannerService {
  static final ScannerService _instance = ScannerService._internal();
  factory ScannerService() => _instance;
  ScannerService._internal();

  Function(String barcode)? _onResult;

  /// Registers a persistent scan result listener (called once at startup).
  /// Re-calling this is safe — it updates the callback and re-registers.
  void startListening(Function(String barcode) onResult) {
    _onResult = onResult;
    _registerAndTrigger();
  }

  /// Programmatically fires the laser to initiate a scan.
  /// Call this whenever the SCAN PRODUCT button is tapped.
  void triggerScan() {
    _registerAndTrigger();
  }

  /// Internal: registers the MethodChannel handler and fires the native scanStart.
  void _registerAndTrigger() {
    ScanSdk.instance.startScan(
      (int code, List<ScanResultBean> results, String? msg) {
        if (code == 0 && results.isNotEmpty) {
          final barcode = results.first.VALUE ?? '';
          if (barcode.isNotEmpty) {
            _onResult?.call(barcode);
          }
        }
      },
    );
  }
}
