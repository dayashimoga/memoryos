import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memoryos/core/blocs/app_blocs.dart';
import 'package:memoryos/core/domain/repositories.dart';
import 'package:memoryos/features/settings/bloc/settings_bloc.dart';

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

  // BLoC singletons
  static late final SettingsBloc _settingsBloc;
  static late final HomeBloc _homeBloc;
  static late final SearchBloc _searchBloc;
  static late final StorageBloc _storageBloc;
  static late final AiBloc _aiBloc;
  static late final CollectionsBloc _collectionsBloc;

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
  }) async {
    if (_initialized) return;

    // Repositories (stubs unless overridden)
    _fileRepo = fileRepo ?? const StubFileRepository();
    _collectionRepo = collectionRepo ?? const StubCollectionRepository();
    _aiRepo = aiRepo ?? const StubAiRepository();
    _searchRepo = searchRepo ?? const StubSearchRepository();
    _storageRepo = storageRepo ?? const StubStorageRepository();
    _thumbnailRepo = thumbnailRepo ?? const StubThumbnailRepository();

    // BLoCs
    _settingsBloc = SettingsBloc();
    _homeBloc = HomeBloc(_fileRepo);
    _searchBloc = SearchBloc(_searchRepo, _fileRepo);
    _storageBloc = StorageBloc(_storageRepo);
    _aiBloc = AiBloc(_aiRepo);
    _collectionsBloc = CollectionsBloc(_collectionRepo);

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

  static SettingsBloc get settingsBloc => _settingsBloc;
  static HomeBloc get homeBloc => _homeBloc;
  static SearchBloc get searchBloc => _searchBloc;
  static StorageBloc get storageBloc => _storageBloc;
  static AiBloc get aiBloc => _aiBloc;
  static CollectionsBloc get collectionsBloc => _collectionsBloc;

  /// All BlocProviders for the widget tree root.
  static List<BlocProvider> get providers => [
        BlocProvider<SettingsBloc>.value(value: _settingsBloc),
        BlocProvider<HomeBloc>.value(value: _homeBloc),
        BlocProvider<SearchBloc>.value(value: _searchBloc),
        BlocProvider<StorageBloc>.value(value: _storageBloc),
        BlocProvider<AiBloc>.value(value: _aiBloc),
        BlocProvider<CollectionsBloc>.value(value: _collectionsBloc),
      ];

  static void dispose() {
    _settingsBloc.close();
    _homeBloc.close();
    _searchBloc.close();
    _storageBloc.close();
    _aiBloc.close();
    _collectionsBloc.close();
    _initialized = false;
  }
}
