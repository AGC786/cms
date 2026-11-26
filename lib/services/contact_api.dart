import 'dart:convert';

import 'package:http/http.dart' as http;

/// Submits the "Contact Us" form to the AIT SmartCampuses API.
class ContactApi {
  ContactApi._();

  static final Uri _url = Uri.parse('https://campus.smartcampuses.com/demo_institute/mobile_app/contact');

  /// Posts [name]/[email]/[message] and returns true only when the server
  /// confirms the message was sent (`status: "success"`). Any network/
  /// parsing failure is treated as a failed send rather than thrown.
  static Future<bool> send({required String name, required String email, required String message}) async {
    try {
      final response = await http
          .post(
            _url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'name': name, 'email': email, 'message': message}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return false;
      // Response body is prefixed with a stray non-JSON snippet before the
      // actual `{"status":"success",...}` payload, so locate the JSON start.
      final jsonStart = response.body.indexOf('{');
      if (jsonStart == -1) return false;
      final decoded = jsonDecode(response.body.substring(jsonStart));
      return decoded is Map && decoded['status'] == 'success';
    } catch (_) {
      return false;
    }
  }
}
