import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'session_manager.dart';

/// Thrown for connectivity-class failures (timeout, no DNS, no socket,
/// the underlying `http.ClientException`) — these must never be treated
/// as "session expired", since the backend was never actually reached.
class ApiNetworkException implements Exception {
  final String message;
  const ApiNetworkException(this.message);
  @override
  String toString() => message;
}

/// Thrown when there's no local session to attach to an authenticated
/// request — distinct from a network failure or a 401 from the server.
class ApiNoSessionException implements Exception {
  const ApiNoSessionException();
  @override
  String toString() => 'No active session';
}

/// Thrown when the backend rejects the session (401, or a 403 the
/// caller has confirmed means "unauthorized" rather than a business
/// rule). By the time this is thrown, [SessionManager.handleSessionExpired]
/// has already run — callers mainly need this to stop rendering/using
/// whatever data they were mid-request for.
class ApiSessionExpiredException implements Exception {
  const ApiSessionExpiredException();
  @override
  String toString() => 'Session expired';
}

/// Centralized HTTP client for every `Studentportal/*`, `Teacherportal/*`
/// and `Staffportal/*` call in this app. Automatically attaches the
/// `ci_session` cookie from [SessionManager] and reacts to 401/403 by
/// running [SessionManager.handleSessionExpired] exactly once even if
/// several requests fail around the same time.
///
/// This does not replace any existing API service file by itself —
/// individual `*_api.dart` files opt in by calling `ApiClient.instance`
/// instead of `http` directly (see the converted examples: `stu_courses_api.dart`,
/// `fac_leave_status_api.dart`, `comp_slip_api.dart`).
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _defaultTimeout = Duration(seconds: 15);

  /// GET an authenticated endpoint. Throws [ApiNoSessionException] if
  /// there's no local session, [ApiNetworkException] on connectivity
  /// failures, and [ApiSessionExpiredException] on a 401/eligible 403
  /// (after already triggering the global expiration handler).
  ///
  /// Pass `requireSession: false` for endpoints that work without a
  /// login session (rare in this app, but some `Studentportal/*` reads
  /// are public) — the cookie is still attached if one happens to exist.
  /// Pass `treatHtmlBodyAsExpired: false` for endpoints that legitimately
  /// return an HTML page on success (e.g. a portal page scraped for its
  /// `<option>` values) rather than JSON — otherwise a valid response
  /// from such an endpoint is misdiagnosed as an expired session (see
  /// [StuExamApi.fetchBreakdowns]).
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    bool requireSession = true,
    bool treatForbiddenAsExpired = true,
    bool treatHtmlBodyAsExpired = true,
  }) =>
      _send(
        headers: headers,
        requireSession: requireSession,
        treatForbiddenAsExpired: treatForbiddenAsExpired,
        treatHtmlBodyAsExpired: treatHtmlBodyAsExpired,
        withCookie: (h) => http.get(url, headers: h).timeout(_defaultTimeout),
      );

  /// POSTs a JSON/raw [body] to an authenticated endpoint. See [get] for
  /// the exception contract.
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool requireSession = true,
    bool treatForbiddenAsExpired = true,
    bool treatHtmlBodyAsExpired = true,
  }) =>
      _send(
        headers: headers,
        requireSession: requireSession,
        treatForbiddenAsExpired: treatForbiddenAsExpired,
        treatHtmlBodyAsExpired: treatHtmlBodyAsExpired,
        withCookie: (h) => http.post(url, headers: h, body: body).timeout(_defaultTimeout),
      );

  /// POSTs `application/x-www-form-urlencoded` [fields] — the shape most
  /// of this backend's write endpoints expect. See [get] for the
  /// exception contract.
  Future<http.Response> postForm(
    Uri url, {
    required Map<String, String> fields,
    Map<String, String>? extraHeaders,
    bool requireSession = true,
    bool treatForbiddenAsExpired = true,
    bool treatHtmlBodyAsExpired = true,
  }) {
    final headers = {'Content-Type': 'application/x-www-form-urlencoded', ...?extraHeaders};
    return _send(
      headers: headers,
      requireSession: requireSession,
      treatForbiddenAsExpired: treatForbiddenAsExpired,
      treatHtmlBodyAsExpired: treatHtmlBodyAsExpired,
      withCookie: (h) => http.post(url, headers: h, body: fields).timeout(_defaultTimeout),
    );
  }

  Future<http.Response> _send({
    required Map<String, String>? headers,
    required bool requireSession,
    required bool treatForbiddenAsExpired,
    required bool treatHtmlBodyAsExpired,
    required Future<http.Response> Function(Map<String, String> headers) withCookie,
  }) async {
    final cookie = await SessionManager.instance.getCookieHeader();
    if (cookie == null && requireSession) {
      throw const ApiNoSessionException();
    }

    final effectiveHeaders = {
      'Accept': 'application/json',
      ...?headers,
      'Cookie': ?cookie,
    };

    http.Response response;
    try {
      response = await withCookie(effectiveHeaders);
    } on TimeoutException {
      throw const ApiNetworkException('The request timed out. Please check your connection and try again.');
    } on SocketException {
      throw const ApiNetworkException('No internet connection. Please check your network and try again.');
    } on http.ClientException catch (e) {
      throw ApiNetworkException('Network error: ${e.message}');
    }

    // This backend never actually returns 401/403 for an expired/invalid
    // session — confirmed live against a bad cookie on all three
    // session-gated portals: Student replies 200 OK with an HTML page
    // that does `window.location.assign(".../Student")` (a browser
    // redirect to its login page), while Faculty/Employee reply 500
    // with an HTML PHP-error page. Every real success response from
    // this API is JSON, so an HTML *body* on an authenticated call is
    // the session-expired signal here, regardless of status code.
    //
    // NOTE: the `Content-Type` header is NOT usable for this — this
    // backend sends `text/html` on *every* response, success or not
    // (confirmed live: `mobile_app/load_campus`, a public endpoint that
    // reliably returns a genuine JSON array, still comes back with
    // `Content-Type: text/html`). Sniffing the header caused every
    // authenticated request to be misdiagnosed as session-expired —
    // this must check the actual body's first non-whitespace
    // character instead: `<` means an HTML page, `[`/`{` means real
    // JSON.
    final trimmedBody = response.body.trimLeft();
    final looksLikeHtmlRedirect = cookie != null && treatHtmlBodyAsExpired && trimmedBody.startsWith('<');
    final isAuthFailure = response.statusCode == 401 || (treatForbiddenAsExpired && response.statusCode == 403) || looksLikeHtmlRedirect;
    if (isAuthFailure && cookie != null) {
      // Fire-and-forget: don't block the caller's error path on
      // navigation. Guarded internally so concurrent callers only
      // trigger one redirect/snackbar.
      unawaited(SessionManager.instance.handleSessionExpired());
      throw const ApiSessionExpiredException();
    }

    if (response.statusCode == 200) {
      SessionManager.instance.confirmSessionAlive();
    }

    return response;
  }
}
