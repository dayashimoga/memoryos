import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:memoryos/features/home/pages/home_page.dart';
import 'package:memoryos/features/search/pages/search_page.dart';
import 'package:memoryos/features/timeline/pages/timeline_page.dart';
import 'package:memoryos/features/collections/pages/collections_page.dart';
import 'package:memoryos/features/chat/pages/chat_page.dart';
import 'package:memoryos/features/vault/pages/vault_page.dart';
import 'package:memoryos/features/settings/pages/settings_page.dart';
import 'package:memoryos/features/onboarding/pages/onboarding_page.dart';
import 'package:memoryos/features/file_detail/pages/file_detail_page.dart';
import 'package:memoryos/features/models/pages/models_page.dart';
import 'package:memoryos/features/duplicates/pages/duplicates_page.dart';
import 'package:memoryos/features/learning/pages/learning_page.dart';
import 'package:memoryos/features/shell/shell_page.dart';
import 'package:memoryos/features/inbox/pages/inbox_page.dart';
import 'package:memoryos/features/galaxy/pages/galaxy_page.dart';
import 'package:memoryos/features/toolbox/pages/toolbox_page.dart';

/// Application router — GoRouter ShellRoute with all v1.2 feature routes.
class AppRouter {
  /// Whether onboarding has been completed (set from main.dart).
  static bool _onboardingComplete = false;

  static void setOnboardingComplete(bool value) {
    _onboardingComplete = value;
  }

  static final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final goingToOnboarding = state.uri.path == '/onboarding';
      if (!_onboardingComplete && !goingToOnboarding) {
        return '/onboarding';
      }
      if (_onboardingComplete && goingToOnboarding) {
        return '/';
      }
      return null;
    },
    routes: [
      // ── Onboarding (outside shell) ──────────────────────────────
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // ── Main shell ──────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ShellPage(
          child: child,
          location: state.uri.path,
        ),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => SearchPage(
              initialQuery: state.uri.queryParameters['q'],
            ),
          ),
          GoRoute(
            path: '/timeline',
            builder: (context, state) => const TimelinePage(),
          ),
          GoRoute(
            path: '/collections',
            builder: (context, state) => const CollectionsPage(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatPage(),
          ),
          GoRoute(
            path: '/vault',
            builder: (context, state) => const VaultPage(),
          ),
          GoRoute(
            path: '/learning',
            builder: (context, state) => const LearningPage(),
          ),
          GoRoute(
            path: '/duplicates',
            builder: (context, state) => const DuplicatesPage(),
          ),
          GoRoute(
            path: '/models',
            builder: (context, state) => const ModelsPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/inbox',
            builder: (context, state) => const InboxPage(),
          ),
          GoRoute(
            path: '/toolbox',
            builder: (context, state) => const ToolboxPage(),
          ),
          GoRoute(
            path: '/galaxy',
            builder: (context, state) => const GalaxyPage(),
          ),
          GoRoute(
            path: '/file/:id',
            builder: (context, state) => FileDetailPage(
              fileId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );
}
