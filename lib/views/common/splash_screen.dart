
// lib/views/common/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_router.dart';
import '../../config/constants.dart';
import '../../providers/user_provider.dart';
import '../../config/dependencies.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startStartupFlow();
  }

  Future<void> _startStartupFlow() async {
    await Future.delayed(const Duration(milliseconds: 4500));

    if (!mounted) return;

    // Already signed in? Skip onboarding.
    if (Dependencies.auth.isSignedIn) {
      String target = '/profile-setup';
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      try {
        final profile = await Dependencies.users.getCurrentUserProfile();
        if (profile != null) {
          if (!mounted) return;
          userProvider.updateDistrict(profile.district);
          target = '/home';
        }
      } catch (_) {
        // Offline / server not running — fall back to profile setup.
      }
      // The saved sign-in was rejected (expired or revoked) → start over.
      if (!Dependencies.auth.isSignedIn) {
        _navigateToLanguage();
        return;
      }
      final navigatorContext = rootNavigatorKey.currentContext;
      if (!mounted || _hasNavigated || navigatorContext == null) return;
      _hasNavigated = true;
      GoRouter.of(navigatorContext).go(target);
      return;
    }

    _navigateToLanguage();
  }

  void _navigateToLanguage() {
    if (!mounted || _hasNavigated) return;

    final navigatorContext = rootNavigatorKey.currentContext;

    if (navigatorContext == null) return;

    _hasNavigated = true;

    GoRouter.of(navigatorContext).go('/language');
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    final horizontalPadding =
        (screenWidth * 0.06).clamp(16.0, 40.0);

    final verticalPadding =
        (screenHeight * 0.03).clamp(16.0, 32.0);

    final logoSize =
        (screenWidth * 0.45).clamp(120.0, 180.0);

    final copyrightFontSize =
        (screenWidth * 0.03).clamp(11.0, 14.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            children: [
              SizedBox(
                height: (screenHeight * 0.02).clamp(8.0, 20.0),
              ),

              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _navigateToLanguage,
                    child: SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: Image.asset(
                        AppImages.logo,
                        fit: BoxFit.contain,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Icon(
                            Icons.eco_rounded,
                            color: Color(0xFF2E7D32),
                            size: 64,
                          );
                        },
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(
                      duration: 1200.ms,
                    )
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 1200.ms,
                      curve: Curves.easeOutBack,
                    ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      (screenWidth * 0.05).clamp(
                    8.0,
                    30.0,
                  ),
                ),
                child: Text(
                  'Copyright © 2026 EcoLanka Community (Pvt) Ltd.\n'
                  'All Rights Reserved.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: copyrightFontSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: 600.ms,
                    duration: 800.ms,
                  ),

              SizedBox(
                height: (screenHeight * 0.015).clamp(
                  6.0,
                  16.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
