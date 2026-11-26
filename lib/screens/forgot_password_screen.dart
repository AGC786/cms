import 'dart:math';

import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _ctrl = TextEditingController();
  String? _error;
  String? _portal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _portal ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  void _send() {
    final username = _ctrl.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Please enter a valid email or mobile number.');
      return;
    }

    final generatedOtp = (Random().nextInt(900000) + 100000).toString();
    setState(() => _error = null);
    Navigator.of(context).pushNamed('/otp', arguments: {
      'generatedOtp': generatedOtp,
      'username': username,
      'portal': _portal,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gradientAppBar(context, 'Forgot Password', blue: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 26),
            const CircleAvatar(radius: 32, backgroundColor: Color(0xFFF3ECF3), child: Text('🔑', style: TextStyle(fontSize: 26))),
            const SizedBox(height: 14),
            const Text('Reset your password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Enter the email or mobile number linked to your account and we\'ll send you a reset link.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 22),
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined), hintText: 'you@example.com'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(alignment: Alignment.centerLeft, child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 11.5))),
              ),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: _send, child: const Text('Send Reset Link')),
          ],
        ),
      ),
    );
  }
}
