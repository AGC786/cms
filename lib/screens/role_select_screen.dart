import 'package:flutter/material.dart';
import 'home_main_screen.dart';

/// Kept only for the registered `/role` route's sake — the app always
/// navigates from the splash screen straight to [HomeMainScreen], which
/// already is the "select your portal" screen, so this delegates to it
/// rather than duplicating (and risking drifting from) that design.
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomeMainScreen();
}
