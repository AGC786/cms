import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _resendDisabled = false;
  int _countdown = 60;
  Timer? _timer;
  String? _generatedOtp;
  String? _username;
  String? _portal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _generatedOtp ??= args?['generatedOtp']?.toString();
    _username ??= args?['username']?.toString();
    _portal ??= args?['portal']?.toString();
    if (_timer == null) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
      _resendDisabled = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
        setState(() => _resendDisabled = false);
        return;
      }
      setState(() => _countdown -= 1);
    });
  }

  void _handleResend() {
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Resending OTP to ${_username ?? 'your account'}')),
    );
  }

  void _handleSubmit() {
    final value = _otpCtrl.text.trim();
    if (value.isEmpty || _generatedOtp == null) {
      _showError('Enter the OTP to continue.');
      return;
    }
    if (value == _generatedOtp) {
      Navigator.of(context).pushNamed('/new-password', arguments: {'username': _username, 'portal': _portal});
    } else {
      _showError('Invalid OTP. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text('OTP Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Image.asset('assets/Images/logo-sc.png', width: 180, height: 140),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00558C), Color(0xFFD62285)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Enter the 6-digit OTP sent to your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          hintText: 'Enter OTP',
                          hintStyle: const TextStyle(color: Colors.white70),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.ink,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _resendDisabled ? null : _handleResend,
                        child: Text(
                          _resendDisabled ? 'Resend ${_countdown}s' : 'OTP Not Received? Resend',
                          style: TextStyle(color: Colors.white.withValues(alpha: _resendDisabled ? 0.68 : 1.0)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
