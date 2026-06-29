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

typedef TagFileFunc = Int32 Function(
    Pointer<Utf8> fileId, Pointer<Utf8> tagId);
typedef TagFileDart = int Function(
    Pointer<Utf8> fileId, Pointer<Utf8> tagId);

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
      } else {
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
      _tagList = _lib!
          .lookupFunction<TagListFunc, TagListDart>('memoryos_tag_list');
      _tagCreate = _lib!
          .lookupFunction<TagCreateFunc, TagCreateDart>('memoryos_tag_create');
      _tagFile = _lib!
          .lookupFunction<TagFileFunc, TagFileDart>('memoryos_tag_file');

      // Collections
      _collectionList = _lib!.lookupFunction<CollectionListFunc,
          CollectionListDart>('memoryos_collection_list');
      _collectionCreate = _lib!.lookupFunction<CollectionCreateFunc,
          CollectionCreateDart>('memoryos_collection_create');
      _collectionAddFile = _lib!.lookupFunction<CollectionAddFileFunc,
          CollectionAddFileDart>('memoryos_collection_add_file');

      // Large files & hash
      _getLargeFiles = _lib!.lookupFunction<GetLargeFilesFunc,
          GetLargeFilesDart>('memoryos_get_large_files');
      _hashFile = _lib!
          .lookupFunction<HashFileFunc, HashFileDart>('memoryos_hash_file');
    } catch (e) {
      debugPrint(
          'Failed to load native MemoryOS engine: $e. Falling back to local simulated db.');
      _loadFailed = true;
    }
  }

  static bool get isAvailable => _lib != null && !_loadFailed;

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
}
