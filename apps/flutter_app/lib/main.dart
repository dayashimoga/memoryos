import 'package:flutter/material.dart';
import 'package:memoryos/app/app.dart';
import 'package:memoryos/core/di/service_locator.dart';
import 'package:memoryos/core/router/app_router.dart';
import 'package:memoryos/features/onboarding/pages/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection and core services
  await ServiceLocator.initialize();

  // Check first-launch onboarding status
  final onboardingDone = await isOnboardingComplete();
  AppRouter.setOnboardingComplete(onboardingDone);

  runApp(const MemoryOSApp());
}
