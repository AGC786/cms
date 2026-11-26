import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mock_data.dart';
import '../services/auth_api.dart';
import '../services/session_manager.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = false;
  bool _loading = false;
  String? _error;
  bool _rememberLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_rememberLoaded) {
      _rememberLoaded = true;
      _loadRememberedCredentials();
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedCredentials() async {
    final portalKey = ModalRoute.of(context)!.settings.arguments as String;
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('remembered_username_$portalKey');
    if (!mounted || savedUser == null || savedUser.isEmpty) return;
    setState(() {
      _userCtrl.text = savedUser;
      _passCtrl.text = _decode(prefs.getString('remembered_password_$portalKey'));
      _rememberMe = true;
    });
  }

  /// The saved password is base64-encoded before storage — not real
  /// encryption, just so it isn't sitting in shared_preferences as
  /// literal plaintext. [_decode] is the inverse and tolerates a missing
  /// or malformed value.
  static String _encode(String raw) => base64.encode(utf8.encode(raw));

  static String _decode(String? stored) {
    if (stored == null || stored.isEmpty) return '';
    try {
      return utf8.decode(base64.decode(stored));
    } catch (_) {
      return '';
    }
  }

  Future<void> _login(String portalKey, PortalMeta meta) async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter both username and password.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });

    bool success = false;
    String? requestError;
    try {
      switch (portalKey) {
        case 'admin':
          final result = await AdminAuthApi.login(username: username, password: password);
          success = result.success;
          if (success) {
            await SessionManager.instance.saveSession(
              portal: portalKey,
              sessionCookie: result.sessionCookie ?? '',
              branchId: result.branchId,
            );
          }
        case 'student':
          final result = await StuAuthApi.login(username: username, password: password);
          success = result.success;
          if (success) {
            await SessionManager.instance.saveSession(
              portal: portalKey,
              sessionCookie: result.sessionCookie ?? '',
              studentId: result.studentId,
            );
          }
        case 'faculty':
          final result = await FacAuthApi.login(username: username, password: password);
          success = result.success;
          if (success) {
            await SessionManager.instance.saveSession(
              portal: portalKey,
              sessionCookie: result.sessionCookie ?? '',
              facultyId: result.empId,
              teacherId: result.teacherId,
              branchId: result.branchId,
            );
            if (result.rawProfile != null) await SessionManager.instance.cacheLoginProfile(result.rawProfile!);
          }
        case 'employee':
          final result = await EmpAuthApi.login(username: username, password: password);
          success = result.success;
          if (success) {
            await SessionManager.instance.saveSession(
              portal: portalKey,
              sessionCookie: result.sessionCookie ?? '',
              staffId: result.staffId,
              employeeId: result.staffId,
            );
            if (result.rawProfile != null) await SessionManager.instance.cacheLoginProfile(result.rawProfile!);
          }
      }
    } on AuthApiException catch (error) {
      requestError = error.message;
    } catch (_) {
      requestError = 'Unable to reach the login service. Check your connection and try again.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    if (!mounted) return;
    if (requestError != null) {
      setState(() => _error = requestError);
      return;
    }
    if (!success) {
      setState(() => _error = 'Invalid username or password.');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('remembered_username_$portalKey', username);
      await prefs.setString('remembered_password_$portalKey', _encode(password));
    } else {
      await prefs.remove('remembered_username_$portalKey');
      await prefs.remove('remembered_password_$portalKey');
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(meta.dashboardRoute, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final portalKey = ModalRoute.of(context)!.settings.arguments as String;
    final meta = portalMeta[portalKey]!;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const SizedBox(height: 28),
                            Center(
                              child: Image.asset('assets/Images/logo-sc.png', width: 280, height: 130, fit: BoxFit.contain),
                            ),
                            const SizedBox(height: 48),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xFF1B3F8F), Color(0xFF6A2F8F), Color(0xFFC21F75)],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(meta.name.replaceAll(' Portal', ''), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30)),
                                      const SizedBox(height: 6),
                                      const Text('Login to continue', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                      const SizedBox(height: 40),
                                      _UnderlineField(
                                        controller: _userCtrl,
                                        hint: 'Username',
                                      ),
                                      const SizedBox(height: 26),
                                      _UnderlineField(
                                        controller: _passCtrl,
                                        hint: 'Password',
                                        obscure: _obscure,
                                        suffix: IconButton(
                                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white70, size: 20),
                                          onPressed: () => setState(() => _obscure = !_obscure),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                              checkColor: const Color(0xFF6A2F8F),
                                              fillColor: WidgetStateProperty.resolveWith((states) => Colors.white),
                                              side: const BorderSide(color: Colors.white70),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text('Remember me', style: TextStyle(color: Colors.white, fontSize: 13)),
                                        ],
                                      ),
                                      if (_error != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                          child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: OutlinedButton(
                                          onPressed: _loading ? null : () => _login(portalKey, meta),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.white, width: 1.4),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                          ),
                                          child: _loading
                                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                              : const Text('LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
                                        ),
                                      ),
                                      if (portalKey != 'admin') ...[
                                        const SizedBox(height: 18),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pushNamed('/forgot-password', arguments: portalKey),
                                          child: const Text('Forgot Password?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                        ),
                                      ],
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                gradient: AppColors.footerGradient,
              ),
              child: const Text(
                'www.smartcampuses.com',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  const _UnderlineField({required this.controller, required this.hint, this.obscure = false, this.suffix});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        filled: false,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        suffixIcon: suffix,
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
