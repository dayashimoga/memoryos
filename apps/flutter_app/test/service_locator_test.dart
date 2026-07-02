import 'package:flutter_test/flutter_test.dart';
import 'package:memoryos/core/di/service_locator.dart';
import 'package:memoryos/core/ffi/rust_ffi.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FailurePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async => throw Exception('Failed path provider');
}

class SuccessPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ServiceLocator full lifecycle and getters', () async {
    // 1. First run: Set failing path provider to cover catchError block
    PathProviderPlatform.instance = FailurePathProviderPlatform();
    RustFfi.isAvailableOverride = true;
    RustFfi.initializeMockBindings();
    
    // We cannot call ServiceLocator.initialize() multiple times because of late final fields.
    // So we will first test it with FFI enabled and throwing path provider.
    await ServiceLocator.initialize();
    
    // Wait for the async file initialization futures to run and fail (caught by catchError)
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Attempt double initialization (should return early)
    await ServiceLocator.initialize();

    // Verify all repository getters
    expect(ServiceLocator.fileRepo, isNotNull);
    expect(ServiceLocator.collectionRepo, isNotNull);
    expect(ServiceLocator.aiRepo, isNotNull);
    expect(ServiceLocator.searchRepo, isNotNull);
    expect(ServiceLocator.storageRepo, isNotNull);
    expect(ServiceLocator.thumbnailRepo, isNotNull);
    expect(ServiceLocator.toolboxRepo, isNotNull);

    // Verify all BLoC getters
    expect(ServiceLocator.settingsBloc, isNotNull);
    expect(ServiceLocator.homeBloc, isNotNull);
    expect(ServiceLocator.searchBloc, isNotNull);
    expect(ServiceLocator.storageBloc, isNotNull);
    expect(ServiceLocator.aiBloc, isNotNull);
    expect(ServiceLocator.collectionsBloc, isNotNull);
    expect(ServiceLocator.importBloc, isNotNull);

    // Verify providers list
    expect(ServiceLocator.providers, isNotEmpty);

    // Dispose
    ServiceLocator.dispose();
  });
}
