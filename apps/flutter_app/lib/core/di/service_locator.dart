import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memoryos/core/blocs/app_blocs.dart';
import 'package:memoryos/core/domain/repositories.dart';
import 'package:memoryos/core/domain/ffi_repositories.dart';
import 'package:memoryos/core/ffi/rust_ffi.dart';
import 'package:memoryos/features/settings/bloc/settings_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Production service locator for MemoryOS.
///
/// In Phase 1, all repositories are stubs. Replace with FFI-backed
/// implementations as Rust integration advances.
class ServiceLocator {
  ServiceLocator._();

  // Repository singletons
  static late final FileRepository _fileRepo;
  static late final CollectionRepository _collectionRepo;
  static late final AiRepository _aiRepo;
  static late final SearchRepository _searchRepo;
  static late final StorageRepository _storageRepo;
  static late final ThumbnailRepository _thumbnailRepo;
  static late final ToolboxRepository _toolboxRepo;

  // BLoC singletons
  static late final SettingsBloc _settingsBloc;
  static late final HomeBloc _homeBloc;
  static late final SearchBloc _searchBloc;
  static late final StorageBloc _storageBloc;
  static late final AiBloc _aiBloc;
  static late final CollectionsBloc _collectionsBloc;
  static late final ImportBloc _importBloc;

  static bool _initialized = false;

  /// Initialize the service locator. Must be called before [providers].
  ///
  /// Pass concrete implementations of each repository to wire the real engine.
  static Future<void> initialize({
    FileRepository? fileRepo,
    CollectionRepository? collectionRepo,
    AiRepository? aiRepo,
    SearchRepository? searchRepo,
    StorageRepository? storageRepo,
    ThumbnailRepository? thumbnailRepo,
    ToolboxRepository? toolboxRepo,
  }) async {
    if (_initialized) return;

    // Load Rust FFI Dynamic Library
    RustFfi.initialize();

    // Initialize the Rust engine with a writable data directory in the background.
    // This prevents any platform-channel delays (e.g. path_provider) from blocking app startup.
    if (RustFfi.isAvailable && !kIsWeb) {
      getApplicationDocumentsDirectory().then((dir) {
        final dataDir = '${dir.path}/memoryos';
        final initResult = RustFfi.init(dataDir);
        if (initResult != 0) {
          // ignore: avoid_print
          print('[MemoryOS] RustFfi.init returned $initResult for "$dataDir"');
        }
      }).catchError((e) {
        // ignore: avoid_print
        print('[MemoryOS] Failed to initialize Rust engine data dir: $e');
      });
    }

    // Repositories (stubs unless overridden, fallback internally checks availability)
    _fileRepo = fileRepo ?? const FfiFileRepository();
    _collectionRepo = collectionRepo ?? const FfiCollectionRepository();
    _aiRepo = aiRepo ?? const FfiAiRepository();
    _searchRepo = searchRepo ?? const FfiSearchRepository();
    _storageRepo = storageRepo ?? const FfiStorageRepository();
    _thumbnailRepo = thumbnailRepo ?? const FfiThumbnailRepository();
    _toolboxRepo = toolboxRepo ?? const FfiToolboxRepository();

    // BLoCs
    _settingsBloc = SettingsBloc();
    _homeBloc = HomeBloc(_fileRepo);
    _searchBloc = SearchBloc(_searchRepo, _fileRepo);
    _storageBloc = StorageBloc(_storageRepo);
    _aiBloc = AiBloc(_aiRepo);
    _collectionsBloc = CollectionsBloc(_collectionRepo);
    _importBloc = ImportBloc(_fileRepo, _homeBloc);

    // Kick off initial AI model check
    _aiBloc.add(AiCheckModel());

    _initialized = true;
  }

  // ── Getters ──────────────────────────────────────────────────────

  static FileRepository get fileRepo => _fileRepo;
  static CollectionRepository get collectionRepo => _collectionRepo;
  static AiRepository get aiRepo => _aiRepo;
  static SearchRepository get searchRepo => _searchRepo;
  static StorageRepository get storageRepo => _storageRepo;
  static ThumbnailRepository get thumbnailRepo => _thumbnailRepo;
  static ToolboxRepository get toolboxRepo => _toolboxRepo;

  static SettingsBloc get settingsBloc => _settingsBloc;
  static HomeBloc get homeBloc => _homeBloc;
  static SearchBloc get searchBloc => _searchBloc;
  static StorageBloc get storageBloc => _storageBloc;
  static AiBloc get aiBloc => _aiBloc;
  static CollectionsBloc get collectionsBloc => _collectionsBloc;
  static ImportBloc get importBloc => _importBloc;

  /// All BlocProviders for the widget tree root.
  static List<BlocProvider> get providers => [
        BlocProvider<SettingsBloc>.value(value: _settingsBloc),
        BlocProvider<HomeBloc>.value(value: _homeBloc),
        BlocProvider<SearchBloc>.value(value: _searchBloc),
        BlocProvider<StorageBloc>.value(value: _storageBloc),
        BlocProvider<AiBloc>.value(value: _aiBloc),
        BlocProvider<CollectionsBloc>.value(value: _collectionsBloc),
        BlocProvider<ImportBloc>.value(value: _importBloc),
      ];

  static void dispose() {
    _settingsBloc.close();
    _homeBloc.close();
    _searchBloc.close();
    _storageBloc.close();
    _aiBloc.close();
    _collectionsBloc.close();
    _importBloc.close();
    _initialized = false;
  }
}
