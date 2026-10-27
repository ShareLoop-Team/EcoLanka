// lib/config/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Prefer explicit prefixes for files that might export overlapping symbols:
import '../views/common/splash_screen.dart';
import '../views/common/language_selection_screen.dart' as lang;
import '../views/common/onboarding_screen.dart' as onboarding;
import '../views/common/welcome_screen.dart';

import '../views/auth/phone_number_screen.dart';
import '../views/auth/otp_verification_screen.dart';
import '../views/auth/profile_setup_screen.dart';

import '../views/home/home_screen.dart';

import '../models/item.dart';
import '../models/need.dart';
import '../models/request.dart';
import '../views/admin/admin_reports_screen.dart';
import '../views/items/create_post_screen.dart';
import '../views/items/item_detail_screen.dart';
import '../views/items/my_items_screen.dart';
import '../views/needs/create_need_screen.dart';
import '../views/needs/my_needs_screen.dart';
import '../views/needs/need_detail_screen.dart';
import '../views/notifications/notifications_screen.dart';
import '../views/profile/badges_screen.dart';
import '../views/profile/edit_profile_screen.dart';
import '../views/profile/history_screen.dart';
import '../views/requests/create_request_screen.dart';
import '../views/requests/report_screen.dart';
import '../views/requests/request_detail_screen.dart';
import '../views/requests/review_screen.dart';

// Root navigator key to safely handle navigation from async callbacks or splash
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',

  // Always use the initialLocation instead of the browser's current URL.
  overridePlatformDefaultLocation: true,

  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // Note: use the prefix 'lang.' because we imported language_selection_screen.dart as lang
    GoRoute(
      path: '/language',
      builder: (context, state) => const lang.LanguageSelectionScreen(),
    ),

    // use prefix 'onboarding.' for onboarding screen
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const onboarding.OnboardingScreen(),
    ),

    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),

    GoRoute(
      path: '/phone-number',
      builder: (context, state) => const PhoneNumberScreen(),
    ),

    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        final phoneNumber = state.extra as String;
        return OTPVerificationScreen(phoneNumber: phoneNumber);
      },
    ),

    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),

    // Main app shell (Home · Explore · Share · Requests · Profile)
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),

    // ---------- items ----------
    GoRoute(
      path: '/share',
      builder: (context, state) =>
          CreatePostScreen(forNeed: state.extra is Need ? state.extra as Need : null),
    ),
    GoRoute(
      path: '/my-items',
      builder: (context, state) => const MyItemsScreen(),
    ),
    GoRoute(
      path: '/item/:id',
      builder: (context, state) =>
          ItemDetailScreen(itemId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'request',
          builder: (context, state) =>
              CreateRequestScreen(item: state.extra as Item),
        ),
      ],
    ),

    // ---------- needs (item request posts) ----------
    GoRoute(
      path: '/need/new',
      builder: (context, state) => const CreateNeedScreen(),
    ),
    GoRoute(
      path: '/need/:id',
      builder: (context, state) =>
          NeedDetailScreen(needId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/my-needs',
      builder: (context, state) => const MyNeedsScreen(),
    ),

    // ---------- requests ----------
    GoRoute(
      path: '/request/:id',
      builder: (context, state) =>
          RequestDetailScreen(requestId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/review',
      builder: (context, state) =>
          ReviewScreen(request: state.extra as ShareRequest),
    ),
    GoRoute(
      path: '/report',
      builder: (context, state) {
        final args = state.extra as Map<String, String>;
        return ReportScreen(
          targetType: args['targetType']!,
          targetId: args['targetId']!,
          label: args['label'] ?? '',
        );
      },
    ),

    // ---------- profile ----------
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/badges',
      builder: (context, state) => const BadgesScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/admin/reports',
      builder: (context, state) => const AdminReportsScreen(),
    ),
  ],
);
