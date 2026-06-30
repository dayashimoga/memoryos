import 'package:flutter/material.dart';
import 'package:memoryos/app/app.dart';
import 'package:memoryos/core/di/service_locator.dart';
import 'package:memoryos/core/router/app_router.dart';
import 'package:memoryos/features/onboarding/pages/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize dependency injection and core services
    await ServiceLocator.initialize();
  } catch (e, stackTrace) {
    debugPrint('[MemoryOS] ServiceLocator initialization failed: $e');
    debugPrint(stackTrace.toString());
  }

  bool onboardingDone = false;
  try {
    // Check first-launch onboarding status
    onboardingDone = await isOnboardingComplete();
  } catch (e, stackTrace) {
    debugPrint('[MemoryOS] Onboarding check failed: $e');
    debugPrint(stackTrace.toString());
  }
  AppRouter.setOnboardingComplete(onboardingDone);

  runApp(const MemoryOSApp());
}
