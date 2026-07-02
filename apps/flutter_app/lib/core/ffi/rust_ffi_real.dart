import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

// Native FFI signatures
typedef InitFunc = Int32 Function(Pointer<Utf8> dataDir);
typedef InitDart = int Function(Pointer<Utf8> dataDir);

typedef IsInitFunc = Int32 Function();
typedef IsInitDart = int Function();

typedef VersionFunc = Pointer<Utf8> Function();
typedef VersionDart = Pointer<Utf8> Function();

typedef FreeStringFunc = Void Function(Pointer<Utf8> ptr);
typedef FreeStringDart = void Function(Pointer<Utf8> ptr);

typedef CountFilesFunc = Int64 Function();
typedef CountFilesDart = int Function();

typedef ListFilesFunc = Pointer<Utf8> Function(Int32 limit, Int32 offset);
typedef ListFilesDart = Pointer<Utf8> Function(int limit, int offset);

typedef GetFileFunc = Pointer<Utf8> Function(Pointer<Utf8> id);
typedef GetFileDart = Pointer<Utf8> Function(Pointer<Utf8> id);

typedef SearchFunc = Pointer<Utf8> Function(Pointer<Utf8> query);
typedef SearchDart = Pointer<Utf8> Function(Pointer<Utf8> query);

typedef StorageStatsFunc = Pointer<Utf8> Function();
typedef StorageStatsDart = Pointer<Utf8> Function();

typedef IndexFileFunc = Int32 Function(Pointer<Utf8> path);
typedef IndexFileDart = int Function(Pointer<Utf8> path);

typedef BatchDeleteFunc = Int32 Function(Pointer<Utf8> ids);
typedef BatchDeleteDart = int Function(Pointer<Utf8> ids);

typedef VaultAddFunc = Int32 Function(Pointer<Utf8> id);
typedef VaultAddDart = int Function(Pointer<Utf8> id);

typedef VaultRemoveFunc = Int32 Function(Pointer<Utf8> id);
typedef VaultRemoveDart = int Function(Pointer<Utf8> id);

typedef VaultListFunc = Pointer<Utf8> Function();
typedef VaultListDart = Pointer<Utf8> Function();

typedef ConvertDocFunc = Int32 Function(
    Pointer<Utf8> inputPath, Pointer<Utf8> outputPath);
typedef ConvertDocDart = int Function(
    Pointer<Utf8> inputPath, Pointer<Utf8> outputPath);

typedef ProcessImageFunc = Int32 Function(Pointer<Utf8> inputPath,
    Pointer<Utf8> outputPath, Int32 width, Int32 height, Int32 quality);
typedef ProcessImageDart = int Function(Pointer<Utf8> inputPath,
    Pointer<Utf8> outputPath, int width, int height, int quality);

typedef NormalizeWavFunc = Int32 Function(
    Pointer<Utf8> inputPath, Pointer<Utf8> outputPath);
typedef NormalizeWavDart = int Function(
    Pointer<Utf8> inputPath, Pointer<Utf8> outputPath);

typedef ArchiveListFunc = Pointer<Utf8> Function(Pointer<Utf8> archivePath);
typedef ArchiveListDart = Pointer<Utf8> Function(Pointer<Utf8> archivePath);

typedef ArchiveCreateFunc = Int32 Function(
    Pointer<Utf8> outputPath, Pointer<Utf8> paths);
typedef ArchiveCreateDart = int Function(
    Pointer<Utf8> outputPath, Pointer<Utf8> paths);

typedef ArchiveExtractFunc = Int32 Function(
    Pointer<Utf8> archivePath, Pointer<Utf8> outputDir);
typedef ArchiveExtractDart = int Function(
    Pointer<Utf8> archivePath, Pointer<Utf8> outputDir);

typedef BackupPerformFunc = Int32 Function(
    Pointer<Utf8> dataDir, Pointer<Utf8> backupPath, Pointer<Utf8> keyPhrase);
typedef BackupPerformDart = int Function(
    Pointer<Utf8> dataDir, Pointer<Utf8> backupPath, Pointer<Utf8> keyPhrase);

typedef BackupRestoreFunc = Int32 Function(
    Pointer<Utf8> backupPath, Pointer<Utf8> dataDir, Pointer<Utf8> keyPhrase);
typedef BackupRestoreDart = int Function(
    Pointer<Utf8> backupPath, Pointer<Utf8> dataDir, Pointer<Utf8> keyPhrase);

// Tag FFI
typedef TagListFunc = Pointer<Utf8> Function();
typedef TagListDart = Pointer<Utf8> Function();

typedef TagCreateFunc = Int32 Function(Pointer<Utf8> name, Pointer<Utf8> color);
typedef TagCreateDart = int Function(Pointer<Utf8> name, Pointer<Utf8> color);

typedef TagFileFunc = Int32 Function(Pointer<Utf8> fileId, Pointer<Utf8> tagId);
typedef TagFileDart = int Function(Pointer<Utf8> fileId, Pointer<Utf8> tagId);

// Collection FFI
typedef CollectionListFunc = Pointer<Utf8> Function();
typedef CollectionListDart = Pointer<Utf8> Function();

typedef CollectionCreateFunc = Int32 Function(
    Pointer<Utf8> name, Pointer<Utf8> description);
typedef CollectionCreateDart = int Function(
    Pointer<Utf8> name, Pointer<Utf8> description);

typedef CollectionAddFileFunc = Int32 Function(
    Pointer<Utf8> collectionId, Pointer<Utf8> fileId);
typedef CollectionAddFileDart = int Function(
    Pointer<Utf8> collectionId, Pointer<Utf8> fileId);

// Large files FFI
typedef GetLargeFilesFunc = Pointer<Utf8> Function(Int32 minSizeMb);
typedef GetLargeFilesDart = Pointer<Utf8> Function(int minSizeMb);

// Hash FFI
typedef HashFileFunc = Int32 Function(Pointer<Utf8> fileId);
typedef HashFileDart = int Function(Pointer<Utf8> fileId);

class RustFfi {
  static DynamicLibrary? _lib;
  static bool _loadFailed = false;

  // Bindings
  static InitDart? _init;
  static IsInitDart? _isInitialized;
  static VersionDart? _version;
  static FreeStringDart? _freeString;
  static CountFilesDart? _countFiles;
  static ListFilesDart? _listFiles;
  static GetFileDart? _getFile;
  static SearchDart? _search;
  static StorageStatsDart? _storageStats;
  static IndexFileDart? _indexFile;
  static BatchDeleteDart? _batchDelete;
  static VaultAddDart? _vaultAdd;
  static VaultRemoveDart? _vaultRemove;
  static VaultListDart? _vaultList;

  static ConvertDocDart? _convertDocument;
  static ProcessImageDart? _processImage;
  static NormalizeWavDart? _normalizeWav;
  static ArchiveListDart? _archiveList;
  static ArchiveCreateDart? _archiveCreate;
  static ArchiveExtractDart? _archiveExtract;
  static BackupPerformDart? _backupPerform;
  static BackupRestoreDart? _backupRestore;
  static TagListDart? _tagList;
  static TagCreateDart? _tagCreate;
  static TagFileDart? _tagFile;
  static CollectionListDart? _collectionList;
  static CollectionCreateDart? _collectionCreate;
  static CollectionAddFileDart? _collectionAddFile;
  static GetLargeFilesDart? _getLargeFiles;
  static HashFileDart? _hashFile;

  static void initialize() {
    if (kIsWeb) {
      _loadFailed = true;
      return;
    }

    try {
      if (Platform.isWindows) {
        _lib = DynamicLibrary.open('core_engine.dll');
      } else if (Platform.isMacOS) {
        _lib = DynamicLibrary.open('libcore_engine.dylib');
      } else if (Platform.isIOS) {
        // On iOS, the Rust library is statically linked into the process binary.
        _lib = DynamicLibrary.process();
      } else if (Platform.isAndroid) {
        // On Android, the .so is packaged in the APK jniLibs directory.
        // cargo-ndk outputs libcore_engine.so; we pre-load its dependency libraries
        // first to ensure the dynamic linker resolves all imported symbols successfully.
        try {
          DynamicLibrary.open('libai_engine.so');
          DynamicLibrary.open('libduplicate_engine.so');
          DynamicLibrary.open('libocr_engine.so');
          DynamicLibrary.open('libsearch_engine.so');
        } catch (_) {
          // Pre-loading is best-effort — dynamic linker may resolve them on newer Android.
        }
        _lib = DynamicLibrary.open('libcore_engine.so');
      } else {
        // Linux desktop
        _lib = DynamicLibrary.open('libcore_engine.so');
      }

      _init = _lib!.lookupFunction<InitFunc, InitDart>('memoryos_init');
      _isInitialized = _lib!
          .lookupFunction<IsInitFunc, IsInitDart>('memoryos_is_initialized');
      _version =
          _lib!.lookupFunction<VersionFunc, VersionDart>('memoryos_version');
      _freeString = _lib!.lookupFunction<FreeStringFunc, FreeStringDart>(
          'memoryos_free_string');
      _countFiles = _lib!.lookupFunction<CountFilesFunc, CountFilesDart>(
          'memoryos_count_files');
      _listFiles = _lib!
          .lookupFunction<ListFilesFunc, ListFilesDart>('memoryos_list_files');
      _getFile =
          _lib!.lookupFunction<GetFileFunc, GetFileDart>('memoryos_get_file');
      _search = _lib!.lookupFunction<SearchFunc, SearchDart>('memoryos_search');
      _storageStats = _lib!.lookupFunction<StorageStatsFunc, StorageStatsDart>(
          'memoryos_storage_stats');
      _indexFile = _lib!
          .lookupFunction<IndexFileFunc, IndexFileDart>('memoryos_index_file');
      _batchDelete = _lib!.lookupFunction<BatchDeleteFunc, BatchDeleteDart>(
          'memoryos_batch_delete');
      _vaultAdd = _lib!
          .lookupFunction<VaultAddFunc, VaultAddDart>('memoryos_vault_add');
      _vaultRemove = _lib!.lookupFunction<VaultRemoveFunc, VaultRemoveDart>(
          'memoryos_vault_remove');
      _vaultList = _lib!
          .lookupFunction<VaultListFunc, VaultListDart>('memoryos_vault_list');

      _convertDocument = _lib!.lookupFunction<ConvertDocFunc, ConvertDocDart>(
          'memoryos_convert_document');
      _processImage = _lib!.lookupFunction<ProcessImageFunc, ProcessImageDart>(
          'memoryos_process_image');
      _normalizeWav = _lib!.lookupFunction<NormalizeWavFunc, NormalizeWavDart>(
          'memoryos_normalize_wav');
      _archiveList = _lib!.lookupFunction<ArchiveListFunc, ArchiveListDart>(
          'memoryos_archive_list');
      _archiveCreate = _lib!
          .lookupFunction<ArchiveCreateFunc, ArchiveCreateDart>(
              'memoryos_archive_create');
      _archiveExtract = _lib!
          .lookupFunction<ArchiveExtractFunc, ArchiveExtractDart>(
              'memoryos_archive_extract');
      _backupPerform = _lib!
          .lookupFunction<BackupPerformFunc, BackupPerformDart>(
              'memoryos_backup_perform');
      _backupRestore = _lib!
          .lookupFunction<BackupRestoreFunc, BackupRestoreDart>(
              'memoryos_backup_restore');

      // Tags
      _tagList =
          _lib!.lookupFunction<TagListFunc, TagListDart>('memoryos_tag_list');
      _tagCreate = _lib!
          .lookupFunction<TagCreateFunc, TagCreateDart>('memoryos_tag_create');
      _tagFile =
          _lib!.lookupFunction<TagFileFunc, TagFileDart>('memoryos_tag_file');

      // Collections
      _collectionList = _lib!
          .lookupFunction<CollectionListFunc, CollectionListDart>(
              'memoryos_collection_list');
      _collectionCreate = _lib!
          .lookupFunction<CollectionCreateFunc, CollectionCreateDart>(
              'memoryos_collection_create');
      _collectionAddFile = _lib!
          .lookupFunction<CollectionAddFileFunc, CollectionAddFileDart>(
              'memoryos_collection_add_file');

      // Large files & hash
      _getLargeFiles = _lib!
          .lookupFunction<GetLargeFilesFunc, GetLargeFilesDart>(
              'memoryos_get_large_files');
      _hashFile = _lib!
          .lookupFunction<HashFileFunc, HashFileDart>('memoryos_hash_file');
    } catch (e) {
      debugPrint(
          'Failed to load native MemoryOS engine: $e. Falling back to local simulated db.');
      _loadFailed = true;
    }
  }

  static void initializeMockBindings() {
    _init = (Pointer<Utf8> dir) => mockInitResult;
    _isInitialized = () => 0;
    _version = () => '0.1.0'.toNativeUtf8();
    _freeString = (Pointer<Utf8> ptr) {
      try { malloc.free(ptr); } catch (_) {}
    };
    _countFiles = () => 5;
    _listFiles = (int limit, int offset) => '[]'.toNativeUtf8();
    _getFile = (Pointer<Utf8> id) => 'null'.toNativeUtf8();
    _search = (Pointer<Utf8> q) => '[]'.toNativeUtf8();
    _storageStats = () => '{"total_files": 5, "total_bytes": 1000}'.toNativeUtf8();
    _indexFile = (Pointer<Utf8> p) => 0;
    _batchDelete = (Pointer<Utf8> ids) => 0;
    _vaultAdd = (Pointer<Utf8> id) => 0;
    _vaultRemove = (Pointer<Utf8> id) => 0;
    _vaultList = () => '[]'.toNativeUtf8();

    _convertDocument = (Pointer<Utf8> inPtr, Pointer<Utf8> outPtr) => 0;
    _processImage = (Pointer<Utf8> inPtr, Pointer<Utf8> outPtr, int w, int h, int q) => 0;
    _normalizeWav = (Pointer<Utf8> inPtr, Pointer<Utf8> outPtr) => 0;
    _archiveList = (Pointer<Utf8> archivePath) => '[]'.toNativeUtf8();
    _archiveCreate = (Pointer<Utf8> outPtr, Pointer<Utf8> pathsPtr) => 0;
    _archiveExtract = (Pointer<Utf8> archivePtr, Pointer<Utf8> outPtr) => 0;
    _backupPerform = (Pointer<Utf8> dirPtr, Pointer<Utf8> pathPtr, Pointer<Utf8> keyPtr) => 0;
    _backupRestore = (Pointer<Utf8> pathPtr, Pointer<Utf8> dirPtr, Pointer<Utf8> keyPtr) => 0;
    
    _tagList = () => '[]'.toNativeUtf8();
    _tagCreate = (Pointer<Utf8> namePtr, Pointer<Utf8> colorPtr) => 0;
    _tagFile = (Pointer<Utf8> fPtr, Pointer<Utf8> tPtr) => 0;
    
    _collectionList = () => '[]'.toNativeUtf8();
    _collectionCreate = (Pointer<Utf8> namePtr, Pointer<Utf8> descPtr) => 0;
    _collectionAddFile = (Pointer<Utf8> colPtr, Pointer<Utf8> filePtr) => 0;
    
    _getLargeFiles = (int minSize) => '[]'.toNativeUtf8();
    _hashFile = (Pointer<Utf8> fileId) => 0;
  }

  static bool isAvailableOverride = false;
  static bool get isAvailable => isAvailableOverride || (_lib != null && !_loadFailed);
  static int mockInitResult = 0;

  // Invocation Helpers
  static int init(String dataDir) {
    if (!isAvailable) return -1;
    final dirPtr = dataDir.toNativeUtf8();
    final res = _init!(dirPtr);
    malloc.free(dirPtr);
    return res;
  }

  static bool isInitialized() {
    if (!isAvailable) return false;
    return _isInitialized!() == 0;
  }

  static String getVersion() {
    if (!isAvailable) return '0.1.0-stub';
    final ptr = _version!();
    final str = ptr.toDartString();
    _freeString!(ptr);
    return str;
  }

  static int countFiles() {
    if (!isAvailable) return 0;
    return _countFiles!();
  }

  static String listFiles(int limit, int offset) {
    if (!isAvailable) return '[]';
    final ptr = _listFiles!(limit, offset);
    final str = ptr.toDartString();
    _freeString!(ptr);
    return str;
  }

  static String getFile(String id) {
    if (!isAvailable) return 'null';
    final idPtr = id.toNativeUtf8();
    final ptr = _getFile!(idPtr);
    malloc.free(idPtr);
    final str = ptr.toDartString();
    _freeString!(ptr);
    return str;
  }

  static String search(String query) {
    if (!isAvailable) return '[]';
    final queryPtr = query.toNativeUtf8();
    final ptr = _search!(queryPtr);
    malloc.free(queryPtr);
    final str = ptr.toDartString();
    _freeString!(ptr);
    return str;
  }

  static String storageStats() {
    if (!isAvailable) return '{}';
    final ptr = _storageStats!();
    final str = ptr.toDartString();
    _freeString!(ptr);
    return str;
  }

  static int indexFile(String path) {
    if (!isAvailable) return -1;
    final pathPtr = path.toNativeUtf8();
    final res = _indexFile!(pathPtr);
    malloc.free(pathPtr);
    return res;
  }

  static int batchDelete(List<String> ids) {
    if (!isAvailable) return 0;
    final joined = ids.join('\n');
    final idsPtr = joined.toNativeUtf8();
    final res = _batchDelete!(idsPtr);
    malloc.free(idsPtr);
    return res;
  }

  static int vaultAdd(String id) {
    if (!isAvailable) return -1;
    final idPtr = id.toNativeUtf8();
    final res = _vaultAdd!(idPtr);
    malloc.free(idPtr);
    return res;
  }

  static int vaultRemove(String id) {
    if (!isAvailable) return -1;
    final idPtr = id.toNativeUtf8();
    final res = _vaultRemove!(idPtr);
    malloc.free(idPtr);
    return res;
  }

  static String vaultList() {
    if (!isAvailable) return '[]';
    final ptr = _vaultList!();
    final str = ptr.toDartString();
    _freeString!(ptr);
    return str;
  }

  static int convertDocument(String input, String output) {
    if (!isAvailable) return -1;
    final inPtr = input.toNativeUtf8();
    final outPtr = output.toNativeUtf8();
    final res = _convertDocument!(inPtr, outPtr);
    malloc.free(inPtr);
    malloc.free(outPtr);
    return res;
  }

  static int processImage(
      String input, String output, int width, int height, int quality) {
    if (!isAvailable) return -1;
    final inPtr = input.toNativeUtf8();
    final outPtr = output.toNativeUtf8();
    final res = _processImage!(inPtr, outPtr, width, height, quality);
    malloc.free(inPtr);
    malloc.free(outPtr);
    return res;
  }

  static int normalizeWav(String input, String output) {
    if (!isAvailable) return -1;
    final inPtr = input.toNativeUtf8();
    final outPtr = output.toNativeUtf8();
    final res = _normalizeWav!(inPtr, outPtr);
    malloc.free(inPtr);
    malloc.free(outPtr);
    return res;
  }

  static String archiveList(String archivePath) {
    if (!isAvailable) return '[]';
    final pathPtr = archivePath.toNativeUtf8();
    final ptr = _archiveList!(pathPtr);
    malloc.free(pathPtr);
    final str = ptr.toDartString();
    _freeString!(ptr);
    return str;
  }

  static int archiveCreate(String outputPath, List<String> paths) {
    if (!isAvailable) return -1;
    final outPtr = outputPath.toNativeUtf8();
    final pathsPtr = paths.join('\n').toNativeUtf8();
    final res = _archiveCreate!(outPtr, pathsPtr);
    malloc.free(outPtr);
    malloc.free(pathsPtr);
    return res;
  }

  static int archiveExtract(String archivePath, String outputDir) {
    if (!isAvailable) return -1;
    final archivePtr = archivePath.toNativeUtf8();
    final outPtr = outputDir.toNativeUtf8();
    final res = _archiveExtract!(archivePtr, outPtr);
    malloc.free(archivePtr);
    malloc.free(outPtr);
    return res;
  }

  static int backupPerform(
      String dataDir, String backupPath, String keyPhrase) {
    if (!isAvailable) return -1;
    final dirPtr = dataDir.toNativeUtf8();
    final pathPtr = backupPath.toNativeUtf8();
    final keyPtr = keyPhrase.toNativeUtf8();
    final res = _backupPerform!(dirPtr, pathPtr, keyPtr);
    malloc.free(dirPtr);
    malloc.free(pathPtr);
    malloc.free(keyPtr);
    return res;
  }

  static int backupRestore(
      String backupPath, String dataDir, String keyPhrase) {
    if (!isAvailable) return -1;
    final pathPtr = backupPath.toNativeUtf8();
    final dirPtr = dataDir.toNativeUtf8();
    final keyPtr = keyPhrase.toNativeUtf8();
    final res = _backupRestore!(pathPtr, dirPtr, keyPtr);
    malloc.free(pathPtr);
    malloc.free(dirPtr);
    malloc.free(keyPtr);
    return res;
  }

  // ── Tags ──────────────────────────────────────────────────────────

  static String tagList() {
    if (!isAvailable) return '[]';
    final ptr = _tagList!();
    final str = ptr.toDartString();
    _freeString!(ptr);
    return str;
  }

  static int tagCreate(String name, String? color) {
    if (!isAvailable) return -1;
    final namePtr = name.toNativeUtf8();
    final colorPtr = (color ?? '').toNativeUtf8();
    final res = _tagCreate!(namePtr, colorPtr);
    malloc.free(namePtr);
    malloc.free(colorPtr);
    return res;
  }

  static int tagFile(String fileId, String tagId) {
    if (!isAvailable) return -1;
    final fPtr = fileId.toNativeUtf8();
    final tPtr = tagId.toNativeUtf8();
    final res = _tagFile!(fPtr, tPtr);
    malloc.free(fPtr);
    malloc.free(tPtr);
    return res;
  }

  // ── Collections ───────────────────────────────────────────────────

  static String collectionList() {
    if (!isAvailable) return '[]';
    final ptr = _collectionList!();
    final str = ptr.toDartString();
    _freeString!(ptr);
    return str;
  }

  static int collectionCreate(String name, String? description) {
    if (!isAvailable) return -1;
    final namePtr = name.toNativeUtf8();
    final descPtr = (description ?? '').toNativeUtf8();
    final res = _collectionCreate!(namePtr, descPtr);
    malloc.free(namePtr);
    malloc.free(descPtr);
    return res;
  }

  static int collectionAddFile(String collectionId, String fileId) {
    if (!isAvailable) return -1;
    final cPtr = collectionId.toNativeUtf8();
    final fPtr = fileId.toNativeUtf8();
    final res = _collectionAddFile!(cPtr, fPtr);
    malloc.free(cPtr);
    malloc.free(fPtr);
    return res;
  }

  // ── Large files & hash ────────────────────────────────────────────

  static String getLargeFiles(int minSizeMb) {
    if (!isAvailable) return '[]';
    final ptr = _getLargeFiles!(minSizeMb);
    final str = ptr.toDartString();
    _freeString!(ptr);
    return str;
  }

  static int hashFile(String fileId) {
    if (!isAvailable) return -1;
    final idPtr = fileId.toNativeUtf8();
    final res = _hashFile!(idPtr);
    malloc.free(idPtr);
    return res;
  }

  // ── AI Categorization ──────────────────────────────────────────────

  /// Categorize text by keywords. Returns JSON array of category strings.
  static String categorizeText(String text) {
    if (!isAvailable) return '["Unknown"]';
    final textPtr = text.toNativeUtf8();
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>),
          Pointer<Utf8> Function(Pointer<Utf8>)>('memoryos_categorize_text');
      final ptr = func(textPtr);
      final str = ptr.toDartString();
      _freeString!(ptr);
      return str;
    } catch (_) {
      return '["Unknown"]';
    } finally {
      malloc.free(textPtr);
    }
  }

  // ── Favorites ──────────────────────────────────────────────────────

  /// Toggle favorite status for a file. Returns 0 on success.
  static int toggleFavorite(String fileId) {
    if (!isAvailable) return -1;
    final idPtr = fileId.toNativeUtf8();
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<Int32 Function(Pointer<Utf8>),
          int Function(Pointer<Utf8>)>('memoryos_toggle_favorite');
      return func(idPtr);
    } catch (_) {
      return -1;
    } finally {
      malloc.free(idPtr);
    }
  }

  /// List favorite files as JSON array.
  static String listFavorites() {
    if (!isAvailable) return '[]';
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<Pointer<Utf8> Function(),
          Pointer<Utf8> Function()>('memoryos_list_favorites');
      final ptr = func();
      final str = ptr.toDartString();
      _freeString!(ptr);
      return str;
    } catch (_) {
      return '[]';
    }
  }

  // ── Duplicates & Similar ───────────────────────────────────────────

  /// Get groups of duplicate files as JSON.
  static String getDuplicateGroups() {
    if (!isAvailable) return '[]';
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<Pointer<Utf8> Function(),
          Pointer<Utf8> Function()>('memoryos_get_duplicate_groups');
      final ptr = func();
      final str = ptr.toDartString();
      _freeString!(ptr);
      return str;
    } catch (_) {
      return '[]';
    }
  }

  /// Get groups of perceptually similar images as JSON.
  static String getSimilarGroups() {
    if (!isAvailable) return '[]';
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<Pointer<Utf8> Function(),
          Pointer<Utf8> Function()>('memoryos_get_similar_groups');
      final ptr = func();
      final str = ptr.toDartString();
      _freeString!(ptr);
      return str;
    } catch (_) {
      return '[]';
    }
  }

  // ── Recent files ───────────────────────────────────────────────────

  /// Get recently modified files as JSON array.
  static String recentFiles(int limit) {
    if (!isAvailable) return '[]';
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<Pointer<Utf8> Function(Int32),
          Pointer<Utf8> Function(int)>('memoryos_recent_files');
      final ptr = func(limit);
      final str = ptr.toDartString();
      _freeString!(ptr);
      return str;
    } catch (_) {
      return '[]';
    }
  }

  /// Full-text search using FTS5 index.
  static String searchFts(String query) {
    if (!isAvailable) return '[]';
    final queryPtr = query.toNativeUtf8();
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>),
          Pointer<Utf8> Function(Pointer<Utf8>)>('memoryos_search_fts');
      final ptr = func(queryPtr);
      final str = ptr.toDartString();
      _freeString!(ptr);
      return str;
    } catch (_) {
      return '[]';
    } finally {
      malloc.free(queryPtr);
    }
  }

  /// Recursively index all files in a directory.
  static int indexDirectory(String dirPath) {
    if (!isAvailable) return -1;
    final pathPtr = dirPath.toNativeUtf8();
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<Int32 Function(Pointer<Utf8>),
          int Function(Pointer<Utf8>)>('memoryos_index_directory');
      return func(pathPtr);
    } catch (_) {
      return -1;
    } finally {
      malloc.free(pathPtr);
    }
  }

  /// Get files for timeline within date range.
  static String getTimeline(String from, String to, int limit) {
    if (!isAvailable) return '[]';
    final fromPtr = from.toNativeUtf8();
    final toPtr = to.toNativeUtf8();
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Int32),
          Pointer<Utf8> Function(
              Pointer<Utf8>, Pointer<Utf8>, int)>('memoryos_get_timeline');
      final ptr = func(fromPtr, toPtr, limit);
      final str = ptr.toDartString();
      _freeString!(ptr);
      return str;
    } catch (_) {
      return '[]';
    } finally {
      malloc.free(fromPtr);
      malloc.free(toPtr);
    }
  }

  /// List all categories.
  static String listCategories() {
    if (!isAvailable) return '[]';
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<Pointer<Utf8> Function(),
          Pointer<Utf8> Function()>('memoryos_list_categories');
      final ptr = func();
      final str = ptr.toDartString();
      _freeString!(ptr);
      return str;
    } catch (_) {
      return '[]';
    }
  }

  /// Get files in a specific category.
  static String getFilesByCategory(String category) {
    if (!isAvailable) return '[]';
    final catPtr = category.toNativeUtf8();
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>),
          Pointer<Utf8> Function(
              Pointer<Utf8>)>('memoryos_get_files_by_category');
      final ptr = func(catPtr);
      final str = ptr.toDartString();
      _freeString!(ptr);
      return str;
    } catch (_) {
      return '[]';
    } finally {
      malloc.free(catPtr);
    }
  }

  /// Save search query to history.
  static int saveSearchQuery(String query, int resultCount) {
    if (!isAvailable) return -1;
    final queryPtr = query.toNativeUtf8();
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<Int32 Function(Pointer<Utf8>, Int32),
          int Function(Pointer<Utf8>, int)>('memoryos_save_search_query');
      return func(queryPtr, resultCount);
    } catch (_) {
      return -1;
    } finally {
      malloc.free(queryPtr);
    }
  }

  /// Get search history.
  static String getSearchHistory(int limit) {
    if (!isAvailable) return '[]';
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<Pointer<Utf8> Function(Int32),
          Pointer<Utf8> Function(int)>('memoryos_get_search_history');
      final ptr = func(limit);
      final str = ptr.toDartString();
      _freeString!(ptr);
      return str;
    } catch (_) {
      return '[]';
    }
  }

  /// Get processing status.
  static String getProcessingStatus() {
    if (!isAvailable) return '{}';
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<Pointer<Utf8> Function(),
          Pointer<Utf8> Function()>('memoryos_get_processing_status');
      final ptr = func();
      final str = ptr.toDartString();
      _freeString!(ptr);
      return str;
    } catch (_) {
      return '{}';
    }
  }

  /// Generate a thumbnail for an image/file.
  static int generateThumbnail(String inputPath, String outputPath, int size) {
    if (!isAvailable) return -1;
    final inPtr = inputPath.toNativeUtf8();
    final outPtr = outputPath.toNativeUtf8();
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<
          Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32),
          int Function(Pointer<Utf8>, Pointer<Utf8>,
              int)>('memoryos_generate_thumbnail');
      return func(inPtr, outPtr, size);
    } catch (_) {
      return -1;
    } finally {
      malloc.free(inPtr);
      malloc.free(outPtr);
    }
  }

  /// Get files by type.
  static String getFilesByType(String fileType, int limit) {
    if (!isAvailable) return '[]';
    final typePtr = fileType.toNativeUtf8();
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>, Int32),
          Pointer<Utf8> Function(
              Pointer<Utf8>, int)>('memoryos_get_files_by_type');
      final ptr = func(typePtr, limit);
      final str = ptr.toDartString();
      _freeString!(ptr);
      return str;
    } catch (_) {
      return '[]';
    } finally {
      malloc.free(typePtr);
    }
  }

  /// Get files inside a manual collection.
  static String getFilesInCollection(String collectionId) {
    if (!isAvailable) return '[]';
    final idPtr = collectionId.toNativeUtf8();
    try {
      final lib = _lib!;
      final func = lib.lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>),
          Pointer<Utf8> Function(
              Pointer<Utf8>)>('memoryos_get_files_in_collection');
      final ptr = func(idPtr);
      final str = ptr.toDartString();
      _freeString!(ptr);
      return str;
    } catch (_) {
      return '[]';
    } finally {
      malloc.free(idPtr);
    }
  }
}
