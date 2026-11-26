import 'package:flutter/material.dart';
import '../theme.dart';

class HomeMainScreen extends StatefulWidget {
  const HomeMainScreen({super.key});

  @override
  State<HomeMainScreen> createState() => _HomeMainScreenState();
}

class _HomeMainScreenState extends State<HomeMainScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoRotation;
  late final Animation<double> _loginOpacity;

  static const _portals = [
    _PortalOption('Admin', 'Control Center', 'assets/Images/admin.png', 'admin'),
    _PortalOption('Faculty', 'Research Hub', 'assets/Images/faculty.png', 'faculty'),
    _PortalOption('Student', 'Learning Hub', 'assets/Images/student.png', 'student'),
    _PortalOption('Employee', 'Operations', 'assets/Images/employee.png', 'employee'),
  ];

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _logoRotation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    _loginOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );
    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  void _navigateTo(String portal) {
    Navigator.of(context).pushNamed('/login', arguments: portal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: _logoRotation,
              builder: (context, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(_logoRotation.value * 2 * 3.1415926535),
                  child: child,
                );
              },
              child: Image.asset('assets/Images/logo-sc.png', width: 280, height: 130, fit: BoxFit.contain),
            ),
            const SizedBox(height: 48),
            Expanded(
              child: FadeTransition(
                opacity: _loginOpacity,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1B3F8F), Color(0xFF6A2F8F), Color(0xFFC21F75)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    child: Column(
                      children: [
                        const Text(
                          'Select Portal',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26),
                        ),
                        const SizedBox(height: 10),
                        Container(width: 46, height: 3, color: Colors.white70),
                        const SizedBox(height: 32),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 28,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                          children: _portals.map((p) => _PortalTile(option: p, onTap: () => _navigateTo(p.key))).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(gradient: AppColors.footerGradient),
              child: const Text(
                'www.smartcampuses.com',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortalOption {
  final String label;
  final String subtitle;
  final String assetPath;
  final String key;
  const _PortalOption(this.label, this.subtitle, this.assetPath, this.key);
}

class _PortalTile extends StatelessWidget {
  final _PortalOption option;
  final VoidCallback onTap;
  const _PortalTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(option.assetPath, width: 76, height: 76, fit: BoxFit.contain),
          const SizedBox(height: 12),
          Text(option.label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(option.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
        ],
      ),
    );
  }
}
