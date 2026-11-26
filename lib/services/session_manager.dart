import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The four portals this app serves. Mirrors the `portalKey` strings
/// already used by [portalMeta] in `models/mock_data.dart` and by
/// `login_screen.dart`'s route arguments — kept as plain strings (not a
/// enum) for that reason, but funneled through this class so there is
/// exactly one place that knows the SharedPreferences key names.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  static const _kSession = 'ci_session';
  static const _kPortal = 'logged_in_portal';
  static const _kStudentId = 'student_id';
  static const _kFacultyId = 'emp_id'; // faculty's own emp_id (Teacherportal)
  static const _kTeacherId = 't_id';
  static const _kBranchId = 'branch_id';
  static const _kEmployeeId = 'staff_id'; // this backend has one id for Staff Portal
  static const _kStaffId = 'staff_id';
  static const _kInstalledBuild = 'installed_build_number';
  static const _kCachedProfile = 'cached_login_profile';

  /// A global navigator key the app's [MaterialApp] must be built with
  /// (`MaterialApp(navigatorKey: SessionManager.instance.navigatorKey, ...)`)
  /// so session expiration — which can be detected from any API call, on
  /// any screen — can redirect to the login screen without every screen
  /// having to thread a [BuildContext] through to this class.
  final navigatorKey = GlobalKey<NavigatorState>();

  /// Guards against handling the same session-expiration event more than
  /// once when several in-flight requests fail with 401/403 at roughly
  /// the same time (see [handleSessionExpired]).
  bool _handlingExpiration = false;

  // ---------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------

  /// Persists a successful login. [sessionCookie] must be the raw
  /// `ci_session=<value>` pair as already extracted by `auth_api.dart`'s
  /// `_extractSessionCookie` — this method does not touch its shape,
  /// only stores/reads it, so no backend response parsing changes.
  ///
  /// Only call this once the backend has confirmed the credentials *and*
  /// issued a real session cookie — never mark a portal as logged in on
  /// credential success alone (see `login_screen.dart`).
  Future<void> saveSession({
    required String portal,
    required String sessionCookie,
    String? studentId,
    String? facultyId,
    String? teacherId,
    String? branchId,
    String? employeeId,
    String? staffId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSession, sessionCookie);
    await prefs.setString(_kPortal, portal);
    if (studentId != null) await prefs.setString(_kStudentId, studentId);
    if (facultyId != null) await prefs.setString(_kFacultyId, facultyId);
    if (teacherId != null) await prefs.setString(_kTeacherId, teacherId);
    if (branchId != null) await prefs.setString(_kBranchId, branchId);
    if (employeeId != null) await prefs.setString(_kEmployeeId, employeeId);
    if (staffId != null) await prefs.setString(_kStaffId, staffId);

    if (kDebugMode) debugPrint('[SessionManager] saved session for "$portal" (${_mask(sessionCookie)})');
  }

  /// Caches the full JSON object a portal's own login endpoint returned
  /// on success (Faculty/Employee logins return a single rich record —
  /// name, department, designation, gender, contact info, etc. — that
  /// the dedicated "profile" endpoints either don't expose at all or
  /// only partially reconstruct via a roundabout chain of other calls).
  /// [FacProfileApi]/[EmpProfileApi] read this first and only fall back
  /// to their own endpoint when nothing was cached (e.g. a session
  /// restored from a previous app run without a fresh login).
  Future<void> cacheLoginProfile(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedProfile, jsonEncode(data));
  }

  /// The profile cached by [cacheLoginProfile], or null if there isn't
  /// one (never logged in this session, or it failed to decode).
  Future<Map<String, dynamic>?> getCachedLoginProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCachedProfile);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------

  /// The raw `ci_session=<value>` pair, or null if not logged in.
  Future<String?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString(_kSession);
    return (cookie == null || cookie.isEmpty) ? null : cookie;
  }

  /// The `Cookie:` header value for an authenticated request, or null if
  /// there's no local session — callers should treat null as "don't send
  /// this request" rather than sending it cookie-less.
  Future<String?> getCookieHeader() => getSession();

  /// Convenience for building request headers: `{'Cookie': '...'}` plus
  /// [extra] (e.g. `Accept`/`Content-Type`), or null if there's no
  /// session at all.
  Future<Map<String, String>?> getAuthHeaders([Map<String, String>? extra]) async {
    final cookie = await getCookieHeader();
    if (cookie == null) return null;
    return {...?extra, 'Cookie': cookie};
  }

  Future<bool> hasSession() async => (await getSession()) != null;

  Future<String?> getPortal() async => (await SharedPreferences.getInstance()).getString(_kPortal);
  Future<String?> getStudentId() async => (await SharedPreferences.getInstance()).getString(_kStudentId);
  Future<String?> getFacultyId() async => (await SharedPreferences.getInstance()).getString(_kFacultyId);
  Future<String?> getTeacherId() async => (await SharedPreferences.getInstance()).getString(_kTeacherId);
  Future<String?> getBranchId() async => (await SharedPreferences.getInstance()).getString(_kBranchId);
  Future<String?> getEmployeeId() async => (await SharedPreferences.getInstance()).getString(_kEmployeeId);
  Future<String?> getStaffId() async => (await SharedPreferences.getInstance()).getString(_kStaffId);

  /// Route to land on for the currently logged-in portal, matching
  /// `models/mock_data.dart`'s `portalMeta`. Returns null if there's no
  /// recognised portal saved.
  static const Map<String, String> _dashboardRoutes = {
    'admin': '/admin',
    'student': '/student',
    'employee': '/employee',
    'faculty': '/faculty',
  };

  Future<String?> getDashboardRoute() async {
    final portal = await getPortal();
    return portal == null ? null : _dashboardRoutes[portal];
  }

  /// Clears any saved session left over from a previously installed
  /// build. Android keeps a package's SharedPreferences across an APK
  /// overwrite-install (only `flutter run`/uninstall/"clear data" wipes
  /// it), so a session saved while testing an old build — especially
  /// Admin's, which [checkSession] never re-validates against the
  /// server — would otherwise open straight to that portal's dashboard
  /// on every subsequent install, skipping login entirely.
  ///
  /// Compares the installed APK's build number against the one recorded
  /// at the last successful login; clears the session and records the
  /// new number on a mismatch (or on first run, when none is recorded).
  /// Call once, before resolving where the splash screen should go.
  Future<void> clearSessionIfNewBuild() async {
    final info = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    final installedBuild = prefs.getString(_kInstalledBuild);
    if (installedBuild != info.buildNumber) {
      await clearSession();
      await prefs.setString(_kInstalledBuild, info.buildNumber);
    }
  }

  // ---------------------------------------------------------------------
  // Server-side validation
  // ---------------------------------------------------------------------

  /// Confirms the locally stored [_kSession] cookie is still accepted by
  /// the backend, by hitting each portal's own authenticated
  /// profile/dashboard read (the only session-gated endpoints this app
  /// already calls per portal — no session-check endpoint is invented):
  ///
  /// - student  -> `Studentportal/studentportal23`  (via [StuProfileApi])
  /// - faculty  -> `Teacherportal/load_leaves`       (via [FacLeaveStatusApi])
  /// - employee -> `Staffportal/profileInfo/<id>`    (via [EmpProfileApi])
  /// - admin    -> no session-gated read exists anywhere in this app's
  ///               admin API surface (every `*_admin_api.dart` endpoint
  ///               is public / unauthenticated) — there is nothing to
  ///               probe, so an Admin session is only checked locally
  ///               (cookie present) rather than invented against the
  ///               backend. If the Admin backend later exposes a gated
  ///               read, wire it in here the same way as the other three.
  ///
  /// This method intentionally does *not* import those API classes to
  /// avoid a circular dependency (they will be migrated to go through
  /// [ApiClient] over time); instead callers that already have one of
  /// those calls available should prefer running it directly and
  /// reporting the result via [handleSessionExpired] /
  /// [confirmSessionAlive] — see `splash_screen.dart` for the wiring.
  Future<bool> checkSession() async {
    final cookie = await getSession();
    if (cookie == null) return false;
    final portal = await getPortal();
    // Admin has no gated endpoint to probe — see the doc comment above.
    if (portal == 'admin') return true;
    // The actual network probe lives in splash_screen.dart, which calls
    // the right portal's existing profile API directly and then reports
    // the outcome back here — see [confirmSessionAlive]/[handleSessionExpired].
    return true;
  }

  // ---------------------------------------------------------------------
  // Expiration handling
  // ---------------------------------------------------------------------

  /// Call this whenever a server-confirmed-valid response comes back on
  /// an authenticated call. Currently a no-op hook (kept symmetrical with
  /// [handleSessionExpired] for callers/tests that want to assert a
  /// session round-tripped cleanly); reserved for future use such as
  /// sliding-expiry bookkeeping.
  void confirmSessionAlive() {}

  /// Central 401/403 (and idle-timeout — see [IdleTimeoutService]) handler.
  /// Safe to call from multiple concurrent requests — only the first call
  /// actually clears the session and navigates; the rest are no-ops while
  /// that's in flight.
  ///
  /// [reason] overrides the default snackbar message — used by
  /// [IdleTimeoutService] to quote the configured timeout back to the
  /// user (e.g. "...expired after 5 minutes of inactivity").
  Future<void> handleSessionExpired({String? reason}) async {
    if (_handlingExpiration) return;
    _handlingExpiration = true;
    try {
      final portal = await getPortal();
      await clearSession();

      final nav = navigatorKey.currentState;
      if (nav == null) return; // app not attached yet / already torn down

      final loginArgs = portal != null && _dashboardRoutes.containsKey(portal) ? portal : null;
      nav.pushNamedAndRemoveUntil(
        loginArgs != null ? '/login' : '/homeMain',
        (route) => false,
        arguments: loginArgs,
      );

      final messengerContext = nav.overlay?.context;
      if (messengerContext != null) {
        ScaffoldMessenger.of(messengerContext).showSnackBar(
          SnackBar(content: Text(reason ?? 'Your session has expired. Please log in again.')),
        );
      }
    } finally {
      _handlingExpiration = false;
    }
  }

  // ---------------------------------------------------------------------
  // Clear / logout
  // ---------------------------------------------------------------------

  /// Clears every key this manager owns. Does not touch unrelated
  /// SharedPreferences keys the app uses for non-auth purposes (e.g.
  /// `remembered_username` from the "Remember me" checkbox).
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kSession),
      prefs.remove(_kPortal),
      prefs.remove(_kStudentId),
      prefs.remove(_kFacultyId),
      prefs.remove(_kTeacherId),
      prefs.remove(_kBranchId),
      prefs.remove(_kEmployeeId),
      prefs.remove(_kStaffId),
      prefs.remove(_kCachedProfile),
    ]);
  }

  /// User-initiated logout. No backend logout endpoint exists anywhere
  /// in this app's API surface, so this only clears the local session —
  /// exactly what `admin_drawer.dart` / `portal_profile_screen.dart`
  /// already did by hand; they now call this instead. Navigation is left
  /// to the caller since the existing drawers already show a confirm
  /// dialog first and target `/homeMain` (this app's portal-select
  /// screen) rather than `/login` directly.
  Future<void> logout() => clearSession();

  static String _mask(String cookie) {
    if (cookie.length <= 12) return '****';
    return '${cookie.substring(0, 8)}****${cookie.substring(cookie.length - 4)}';
  }
}
