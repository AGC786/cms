import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of a [ChangePasswordApi.changePassword] call.
class ChangePasswordResult {
  final bool success;
  final String message;
  const ChangePasswordResult(this.success, this.message);
}

/// Submits a password change to the AIT SmartCampuses API.
class ChangePasswordApi {
  ChangePasswordApi._();

  static final Uri _url = Uri.parse('https://campus.smartcampuses.com/demo_institute/mobile_app/changePassword');

  static Future<ChangePasswordResult> changePassword({
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            _url,
            headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'username': username, 'cPass': currentPassword, 'nPass': newPassword},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return const ChangePasswordResult(false, 'Error changing password');
      }

      // Server replies either a bare boolean (`false` on failure, observed
      // for an invalid username/old-password combo) or a
      // `{"success": bool, "message": "..."}` object.
      final decoded = jsonDecode(response.body.trim());
      if (decoded is bool) {
        return ChangePasswordResult(decoded, decoded ? 'Password changed successfully' : 'Your old password is incorrect');
      }
      if (decoded is Map) {
        final success = decoded['success'] == true;
        final message = decoded['message']?.toString();
        return ChangePasswordResult(
          success,
          message?.isNotEmpty == true ? message! : (success ? 'Password changed successfully' : 'Error changing password'),
        );
      }
      return const ChangePasswordResult(false, 'Error changing password');
    } catch (_) {
      return const ChangePasswordResult(false, 'Error changing password');
    }
  }
}
