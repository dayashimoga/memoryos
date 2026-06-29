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
}
