import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _msg = TextEditingController();
  String? _error;
  bool _sent = false;

  void _send() {
    final emailValid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim());
    if (_name.text.trim().isEmpty || !emailValid || _msg.text.trim().isEmpty) {
      setState(() {
        _error = 'Please fill in all fields with a valid email.';
        _sent = false;
      });
      return;
    }
    setState(() {
      _error = null;
      _sent = true;
      _name.clear();
      _email.clear();
      _msg.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gradientAppBar(context, 'Contact Us'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ContactIcon(emoji: '📍'),
                SizedBox(width: 12),
                _ContactIcon(emoji: '✉️'),
                SizedBox(width: 12),
                _ContactIcon(emoji: '📞'),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Quick Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: const InputDecoration(hintText: 'Your Name')),
            const SizedBox(height: 10),
            TextField(controller: _email, decoration: const InputDecoration(hintText: 'Your Email')),
            const SizedBox(height: 10),
            TextField(controller: _msg, maxLines: 4, decoration: const InputDecoration(hintText: 'Your Message')),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 11.5)),
              ),
            const SizedBox(height: 6),
            ElevatedButton(onPressed: _send, child: const Text('Send')),
            if (_sent)
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFE9F7EE), borderRadius: BorderRadius.circular(10)),
                child: const Text('✅ Message sent! We\'ll get back to you soon.',
                    textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF1E8A3C), fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactIcon extends StatelessWidget {
  final String emoji;
  const _ContactIcon({required this.emoji});
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(radius: 21, backgroundColor: const Color(0xFF8C1848), child: Text(emoji, style: const TextStyle(fontSize: 16)));
  }
}
