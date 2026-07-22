import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _configUrl = 'https://ssmetre.brite.app/api/ss_meter';
  static const String _statusUrl = 'https://ssmetre.brite.app/api/ss_meter/status';

  /// Saves the device configuration with the backend API.
  /// Returns a Map containing success status and the API response message.
  static Future<Map<String, dynamic>> saveConfig({
    required String deviceId,
    required String branch,
    required int floor,
  }) async {
    final requestBody = jsonEncode({
      'device_id': deviceId,
      'branch': branch,
      'floor': floor,
    });

    print('=== API REQUEST ===');
    print('URL: $_configUrl');
    print('Headers: {Content-Type: application/json, Accept: application/json}');
    print('Body: $requestBody');

    try {
      final response = await http.post(
        Uri.parse(_configUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 15));

      print('=== API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Handle standard JSON-RPC 2.0 response format
        if (responseData.containsKey('result')) {
          final result = responseData['result'];
          if (result is Map<String, dynamic>) {
            final status = result['status'];
            final message = result['message'] ?? 'Meter data saved successfully';
            if (status == 'success') {
              return {
                'success': true,
                'message': message,
                'meter_id': result['meter_id'],
              };
            } else {
              return {
                'success': false,
                'message': message,
              };
            }
          }
        }
        
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: Status code ${response.statusCode}',
        };
      }
    } catch (e) {
      print('=== API ERROR ===');
      print('Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Checks the credit status for the device.
  /// Returns a Map containing status:
  /// - `credit_status`: bool (true if user has enough credit)
  /// - `low_credit`: bool (true if user's credit is running low)
  static Future<Map<String, dynamic>> checkCreditStatus({
    required bool statusCheck,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_serial') ?? '';

      final requestBody = jsonEncode({
        'device_id': deviceId,
        'status_check': statusCheck,
      });

      print('=== API REQUEST (API 2) ===');
      print('URL: $_statusUrl');
      print('Headers: {Content-Type: application/json, Accept: application/json}');
      print('Body: $requestBody');

      final response = await http.post(
        Uri.parse(_statusUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 15));

      print('=== API RESPONSE (API 2) ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData.containsKey('result')) {
          final result = responseData['result'];
          if (result is Map<String, dynamic>) {
            return {
              'success': true,
              'credit_status': result['credit_status'] ?? false,
              'low_credit': result['low_credit'] ?? false,
            };
          }
        }

        return {
          'success': false,
          'message': 'Invalid response format from server',
          'credit_status': false,
          'low_credit': false,
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: Status code ${response.statusCode}',
          'credit_status': false,
          'low_credit': false,
        };
      }
    } catch (e) {
      print('=== API ERROR (API 2) ===');
      print('Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'credit_status': false,
        'low_credit': false,
      };
    }
  }
}
