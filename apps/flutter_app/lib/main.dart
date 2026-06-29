import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memoryos/app/app.dart';
import 'package:memoryos/core/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection and core services
  await ServiceLocator.initialize();

  runApp(const MemoryOSApp());
}
