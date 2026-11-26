import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _clearSessionAndNavigate();
  }

  Future<void> _clearSessionAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ci_session');
    if (!mounted) return;
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/homeMain');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            Center(
              child: Image.asset(
                'assets/Images/logo-sc.png',
                width: 230,
                height: 110,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/Images/splashBack.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 42, left: 24, right: 24),
                          child: Column(
                            children: [
                              Text(
                                'Best Academic',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF9D1F62),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'ERP & LMS',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF9D1F62),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 14),
                              Text(
                                'Schools | Colleges | Universities',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF1A4F8F),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 28),
                          child: Column(
                            children: [
                              Text(
                                'Powered By Digitiz Evolution',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1A4F8F),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _SocialIcon(imagePath: 'assets/Images/instagram_1384015.png'),
                                  SizedBox(width: 12),
                                  _SocialIcon(imagePath: 'assets/Images/facebook_3670014.png'),
                                  SizedBox(width: 12),
                                  _SocialIcon(imagePath: 'assets/Images/linkedin_1384014.png'),
                                  SizedBox(width: 12),
                                  _SocialIcon(imagePath: 'assets/Images/twitter_3669691.png'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD62285),
                    Color(0xFFC13584),
                    Color(0xFF853587),
                    Color(0xFF00558C),
                  ],
                ),
              ),
              child: const Text(
                'www.smartcampuses.com',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final String imagePath;
  const _SocialIcon({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      height: 25,
      width: 25,
      color: const Color(0xFF00558C),
      fit: BoxFit.contain,
    );
  }
}
