import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthApiException implements Exception {
  final String message;
  const AuthApiException(this.message);

  @override
  String toString() => message;
}

/// Mod_Security on this backend has repeatedly been observed (on several
/// other endpoints in this app) to block requests whose `User-Agent`
/// doesn't look like a real mobile browser. Every login call below sends
/// this same browser-like UA defensively.
const _loginHeaders = {
  'Content-Type': 'application/x-www-form-urlencoded',
  'User-Agent': 'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
};

/// This backend is inconsistent about whether a "success" status flag is
/// a JSON bool, an int, or a numeric string across its different login
/// endpoints — so every status check below goes through this loose
/// truthy comparison instead of a strict `== true` / `== 1`, to avoid
/// silently rejecting a valid login over a type mismatch.
bool _statusTruthy(dynamic status) =>
    status == true || status == 1 || (status is String && {'1', 'true'}.contains(status.trim().toLowerCase()));

/// Extracts the `ci_session=<value>` pair from a `Set-Cookie` response
/// header, in the form expected by the `Cookie:` request header on
/// later session-gated calls. Present on every response (even failed
/// logins get *a* session cookie) — it only carries a populated PHP
/// session once the server has actually recognised valid credentials.
String? _extractSessionCookie(http.Response response) {
  final setCookie = response.headers['set-cookie'];
  final match = setCookie != null ? RegExp(r'ci_session=([^;]+)').firstMatch(setCookie) : null;
  return match != null ? 'ci_session=${match.group(1)}' : null;
}

/// POSTs [username]/[password] as form data to [url] with the shared
/// login headers. Debug output reports response metadata only; it never
/// logs credentials, response bodies, or session cookies.
Future<http.Response> _postLogin(Uri url, {required String username, required String password, String? debugLabel}) async {
  final response = await http
      .post(url, headers: _loginHeaders, body: {'username': username, 'password': password})
      .timeout(const Duration(seconds: 15));
  // Keep diagnostics free of credentials, profile data, and session cookies.
  if (debugLabel != null && kDebugMode) {
    // ignore: avoid_print
    print('[$debugLabel] status=${response.statusCode} contentType=${response.headers['content-type']} bodyBytes=${response.bodyBytes.length}');
  }
  return response;
}

/// Result of an [AuthApi.login] call.
class LoginResult {
  final bool success;
  /// The `ci_session=...` cookie value from the response, when present —
  /// needed by session-gated endpoints like the Staff Portal's
  /// compensation slips. Only meaningful when [success] is true and the
  /// server actually recognised the credentials (a cookie is issued for
  /// every request, but it only carries a populated session when login
  /// genuinely succeeds server-side).
  final String? sessionCookie;
  const LoginResult(this.success, this.sessionCookie);
}

/// Talks to the AIT SmartCampuses generic login API. Confirmed working
/// with real Admin credentials; Student/Faculty/Employee accounts live
/// in separate portal-specific tables this endpoint doesn't check (a
/// real Student login was confirmed to fail here even with correct
/// credentials) — see [StuAuthApi]/[FacAuthApi]/[EmpAuthApi] for those.
class AuthApi {
  AuthApi._();

  static final Uri _loginUrl = Uri.parse('https://campus.smartcampuses.com/demo_institute/ApiController/password1forangular');

  /// Posts [username]/[password] and returns true only when the server
  /// confirms the credentials are valid. Network and malformed-response
  /// failures throw [AuthApiException] so they aren't reported as bad credentials.
  static Future<bool> login({required String username, required String password}) async {
    return (await loginWithSession(username: username, password: password)).success;
  }

  /// Same as [login], but also returns the session cookie issued by the
  /// server so callers can persist it for later session-gated requests.
  static Future<LoginResult> loginWithSession({required String username, required String password}) async {
    try {
      final response = await _postLogin(_loginUrl, username: username, password: password, debugLabel: 'AdminAuthApi');
      if (response.statusCode != 200) {
        throw AuthApiException('Login server returned HTTP ${response.statusCode}.');
      }

      // Server replies `{"status": <truthy on success>, "sessionData": [...]}`.
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const AuthApiException('Login server returned an unexpected response.');
      }
      final success = _statusTruthy(decoded['status']);
      if (success && decoded['sessionData'] is! Map) {
        throw const AuthApiException('Login server returned incomplete account data.');
      }

      return LoginResult(success, _extractSessionCookie(response));
    } on FormatException {
      throw const AuthApiException('Login server returned an unreadable response.');
    }
  }
}

/// Result of a [StuAuthApi.login] call.
class StuLoginResult {
  final bool success;
  final String? sessionCookie;
  final String? studentId;
  const StuLoginResult(this.success, this.sessionCookie, this.studentId);
}

/// Talks to the Student portal's own login endpoint — the one that
/// actually populates the PHP session (`student_id`) that every
/// session-gated `Studentportal/*` read (courses, notices, fee
/// invoices, exam schedule, ...) requires.
///
/// NOTE: the success-path response shape below is inferred from the RN
/// source, not confirmed against a real login (only the failure shape,
/// `{"status":0,"sessionData":null}`, has been observed directly). A
/// temporary debug print is left in `login()` — check the console after
/// a real login attempt and report the printed line back if this still
/// rejects valid credentials, so the parsing can be corrected against
/// the real response instead of guessed at again.
class StuAuthApi {
  StuAuthApi._();

  static final Uri _loginUrl = Uri.parse('https://campus.smartcampuses.com/demo_institute/Studentportal/username1forangular');

  static Future<StuLoginResult> login({required String username, required String password}) async {
    try {
      final response = await _postLogin(_loginUrl, username: username, password: password, debugLabel: 'StuAuthApi');
      if (response.statusCode != 200) {
        throw AuthApiException('Login server returned HTTP ${response.statusCode}.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const AuthApiException('Login server returned an unexpected response.');
      }
      final sessionData = decoded['sessionData'];
      final success = _statusTruthy(decoded['status']);
      if (success && (sessionData is! Map || sessionData.isEmpty)) {
        throw const AuthApiException('Login server returned incomplete student account data.');
      }

      final studentId = success ? sessionData['student_id']?.toString() : null;
      return StuLoginResult(success, _extractSessionCookie(response), studentId);
    } on FormatException {
      throw const AuthApiException('Login server returned an unreadable response.');
    }
  }
}

/// Result of a [FacAuthApi.login] call.
class FacLoginResult {
  final bool success;
  final String? sessionCookie;
  final String? empId;
  final String? branchId;
  final String? teacherId;
  /// The full decoded login response on success — confirmed live to be a
  /// single rich record (name, `dept_name`/`Department`, `designation`,
  /// `gender`, `father_name`, `mobile_no`, `email_address`,
  /// `qualification`, `picture`, ...), i.e. this endpoint already *is*
  /// the faculty's profile. Callers should cache this
  /// ([SessionManager.cacheLoginProfile]) rather than re-deriving a
  /// partial profile from another endpoint.
  final Map<String, dynamic>? rawProfile;
  const FacLoginResult(this.success, this.sessionCookie, this.empId, this.branchId, this.teacherId, [this.rawProfile]);
}

/// Talks to the Faculty portal's own login endpoint — the one that
/// actually populates the PHP session that every session-gated
/// `Teacherportal/*` read requires.
///
/// Both response shapes are now confirmed live: failure is a bare `0`;
/// success is a JSON object with a `username` field (plus the faculty's
/// full profile — see [FacLoginResult.rawProfile]).
class FacAuthApi {
  FacAuthApi._();

  static final Uri _loginUrl = Uri.parse('https://campus.smartcampuses.com/demo_institute/Teacherportal/username2');

  static Future<FacLoginResult> login({required String username, required String password}) async {
    try {
      final response = await _postLogin(_loginUrl, username: username, password: password, debugLabel: 'FacAuthApi');
      if (response.statusCode != 200) {
        throw AuthApiException('Login server returned HTTP ${response.statusCode}.');
      }

      final body = response.body.trim();
      final decoded = (body.isEmpty || body == '0') ? null : jsonDecode(body);
      if (decoded != null && decoded is! Map) {
        throw const AuthApiException('Login server returned an unexpected response.');
      }
      final success = decoded is Map && decoded['username'] != null;

      return FacLoginResult(
        success,
        _extractSessionCookie(response),
        success ? decoded['emp_id']?.toString() : null,
        success ? decoded['branch_id']?.toString() : null,
        success ? decoded['t_id']?.toString() : null,
        success ? decoded.map((k, v) => MapEntry(k.toString(), v)) : null,
      );
    } on FormatException {
      throw const AuthApiException('Login server returned an unreadable response.');
    }
  }
}

/// Result of an [EmpAuthApi.login] call.
class EmpLoginResult {
  final bool success;
  final String? sessionCookie;
  final String? staffId;
  final String? staffName;
  /// The full decoded login response on success, mirroring
  /// [FacLoginResult.rawProfile] (confirmed live to carry a full profile
  /// for Faculty) — unconfirmed live for Employee since no test
  /// credentials were available, so callers must still fall back
  /// gracefully when this is null or missing fields.
  final Map<String, dynamic>? rawProfile;
  const EmpLoginResult(this.success, this.sessionCookie, this.staffId, this.staffName, [this.rawProfile]);
}

/// Talks to the Employee (Staff) portal's own login endpoint — the one
/// that actually populates the PHP session that every session-gated
/// `Staffportal/*` read (compensation slip, leave balance/status,
/// salary slip, profile, ...) requires.
///
/// NOTE: only the failure shape (a bare `null`) has been confirmed
/// directly; the success shape is inferred from the RN source. Debug
/// print left in `login()` — see [StuAuthApi]'s note.
class EmpAuthApi {
  EmpAuthApi._();

  static final Uri _loginUrl = Uri.parse('https://campus.smartcampuses.com/demo_institute/Staffportal/loginForApp');

  static Future<EmpLoginResult> login({required String username, required String password}) async {
    try {
      final response = await _postLogin(_loginUrl, username: username, password: password, debugLabel: 'EmpAuthApi');
      if (response.statusCode != 200) {
        throw AuthApiException('Login server returned HTTP ${response.statusCode}.');
      }

      final body = response.body.trim();
      final decoded = (body.isEmpty || body == 'null') ? null : jsonDecode(body);
      if (decoded != null && decoded is! Map) {
        throw const AuthApiException('Login server returned an unexpected response.');
      }
      final success = decoded is Map && _statusTruthy(decoded['status']) && decoded['username'] != null;

      return EmpLoginResult(
        success,
        _extractSessionCookie(response),
        success ? decoded['staff_id']?.toString() : null,
        success ? decoded['staff_name']?.toString() : null,
        success ? decoded.map((k, v) => MapEntry(k.toString(), v)) : null,
      );
    } on FormatException {
      throw const AuthApiException('Login server returned an unreadable response.');
    }
  }
}

/// Result of an [AdminAuthApi.login] call.
class AdminLoginResult {
  final bool success;
  final String? sessionCookie;
  final String? username;
  final String? branchId;
  const AdminLoginResult(this.success, this.sessionCookie, this.username, this.branchId);
}

/// Talks to the Admin portal's own login endpoint (the one the RN Admin
/// app itself calls) — confirmed working end-to-end with real Admin
/// credentials.
class AdminAuthApi {
  AdminAuthApi._();

  static final Uri _loginUrl = Uri.parse('https://campus.smartcampuses.com/demo_institute/Checkingcontroller/password1forangular');

  static Future<AdminLoginResult> login({required String username, required String password}) async {
    try {
      final response = await _postLogin(_loginUrl, username: username, password: password);
      if (response.statusCode != 200) {
        throw AuthApiException('Login server returned HTTP ${response.statusCode}.');
      }

      // Server replies `{"status": <truthy on success>, "sessionData": {...}}`.
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const AuthApiException('Login server returned an unexpected response.');
      }
      final sessionData = decoded['sessionData'];
      final success = _statusTruthy(decoded['status']);
      if (success && (sessionData is! Map || sessionData.isEmpty)) {
        throw const AuthApiException('Login server returned incomplete admin account data.');
      }

      return AdminLoginResult(
        success,
        _extractSessionCookie(response),
        success ? sessionData['username']?.toString() : null,
        success ? sessionData['branch_id']?.toString() : null,
      );
    } on FormatException {
      throw const AuthApiException('Login server returned an unreadable response.');
    }
  }
}
