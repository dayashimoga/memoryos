import 'dart:convert';
import 'dart:typed_data';
import 'package:memoryos/core/domain/entities.dart';
import 'package:memoryos/core/domain/repositories.dart';
import 'package:memoryos/core/ffi/rust_ffi.dart';

class FfiFileRepository implements FileRepository {
  final FileRepository _fallback = const StubFileRepository();

  const FfiFileRepository();

  FileEntry _parseFileEntry(Map<String, dynamic> map) {
    return FileEntry(
      id: map['id'] ?? '',
      path: map['path'] ?? '',
      filename: map['filename'] ?? '',
      extension: map['extension'] ?? '',
      fileType: FileType.fromExtension(map['extension'] ?? ''),
      sizeBytes: map['size_bytes'] ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      modifiedAt: DateTime.tryParse(map['modified_at'] ?? '') ?? DateTime.now(),
      tags: List<String>.from(map['tags'] ?? []),
      summary: map['summary'],
      indexingStatus: IndexingStatus.completed,
      isFavorite: map['is_encrypted'] == true || false,
    );
  }

  @override
  Future<List<FileEntry>> getRecentFiles(
      {int limit = 50, int offset = 0}) async {
    if (!RustFfi.isAvailable)
      return _fallback.getRecentFiles(limit: limit, offset: offset);
    try {
      final jsonStr = RustFfi.listFiles(limit, offset);
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((item) => _parseFileEntry(item)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<FileEntry>> searchFiles(String query,
      {String? typeFilter,
      SearchRanking ranking = SearchRanking.relevance}) async {
    if (!RustFfi.isAvailable)
      return _fallback.searchFiles(query,
          typeFilter: typeFilter, ranking: ranking);
    try {
      final jsonStr = RustFfi.search(query);
      final List decoded = jsonDecode(jsonStr);
      final list = decoded
          .map((item) {
            // Rust search returns RankedFileItem or SearchResultItem: { file_id, score, snippet, match_type }
            // We will fetch the actual file details from Rust FFI by ID or parse it directly
            final fileId = item['file_id'] ?? '';
            final fileJson = RustFfi.getFile(fileId);
            if (fileJson == 'null') return null;
            return _parseFileEntry(jsonDecode(fileJson));
          })
          .whereType<FileEntry>()
          .toList();

      if (typeFilter != null) {
        final filter = typeFilter.toLowerCase();
        return list.where((f) => f.extension.toLowerCase() == filter).toList();
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<FileEntry>> getFilesByTag(String tagId) async {
    return _fallback.getFilesByTag(tagId);
  }

  @override
  Future<List<FileEntry>> getFilesInCollection(String collectionId) async {
    return _fallback.getFilesInCollection(collectionId);
  }

  @override
  Future<FileEntry?> getFileById(String id) async {
    if (!RustFfi.isAvailable) return _fallback.getFileById(id);
    try {
      final jsonStr = RustFfi.getFile(id);
      if (jsonStr == 'null') return null;
      return _parseFileEntry(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StorageStats> getStorageStats() async {
    if (!RustFfi.isAvailable) return _fallback.getStorageStats();
    try {
      final jsonStr = RustFfi.storageStats();
      final map = jsonDecode(jsonStr);
      return StorageStats(
        totalFiles: map['total_files'] ?? 0,
        totalSizeBytes: map['total_bytes'] ?? 0,
        usedSizeBytes: map['total_bytes'] ?? 0,
        duplicateSizeBytes: map['duplicate_bytes'] ?? 0,
        blurryImageCount: map['blurry_count'] ?? 0,
      );
    } catch (_) {
      return const StorageStats();
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {}

  @override
  Future<void> deleteFile(String id) async {
    if (RustFfi.isAvailable) {
      RustFfi.batchDelete([id]);
    }
  }

  @override
  Future<List<FileEntry>> getDuplicates() async => [];

  @override
  Future<List<FileEntry>> getBlurryImages() async => [];

  @override
  Future<List<FileEntry>> getLargeFiles({int minSizeMb = 50}) async => [];

  @override
  Future<List<FileEntry>> getFavorites() async => [];

  @override
  Future<List<FileEntry>> getByDateRange(DateTime from, DateTime to) async =>
      [];

  @override
  Future<List<FileEntry>> getSimilarFiles(String fileId) async => [];

  @override
  Future<void> importFile(String path) async {
    if (RustFfi.isAvailable) {
      RustFfi.indexFile(path);
    }
  }

  @override
  Future<void> batchDelete(List<String> ids) async {
    if (RustFfi.isAvailable) {
      RustFfi.batchDelete(ids);
    }
  }

  @override
  Future<void> batchTag(List<String> ids, List<String> tags) async {}

  @override
  Future<void> batchMove(List<String> ids, String collectionId) async {}

  @override
  Future<List<String>> getSearchHistory() async => [];

  @override
  Future<void> saveSearchQuery(String query) async {}

  @override
  Future<IndexStats> getIndexStats() async {
    if (!RustFfi.isAvailable) return const IndexStats();
    try {
      final jsonStr = RustFfi.storageStats();
      final map = jsonDecode(jsonStr);
      return IndexStats(
        indexedFiles: map['indexed_files'] ?? 0,
        pendingFiles: map['pending_files'] ?? 0,
        failedFiles: 0,
        isRunning: false,
      );
    } catch (_) {
      return const IndexStats();
    }
  }
}

class FfiAiRepository implements AiRepository {
  final AiRepository _fallback = const StubAiRepository();

  const FfiAiRepository();

  @override
  Future<String> summarize(String fileId) async => _fallback.summarize(fileId);

  @override
  Future<String> explainScreenshot(String fileId) async =>
      _fallback.explainScreenshot(fileId);

  @override
  Future<String> explainCode(String fileId) async =>
      _fallback.explainCode(fileId);

  @override
  Future<String> explainDiagram(String fileId) async =>
      _fallback.explainDiagram(fileId);

  @override
  Future<String> chat(String message, List<ChatMessage> history) async =>
      _fallback.chat(message, history);

  @override
  Future<List<Flashcard>> generateFlashcards(String fileId) async =>
      _fallback.generateFlashcards(fileId);

  @override
  Future<List<String>> autoTag(String fileId) async =>
      _fallback.autoTag(fileId);

  @override
  Future<String> suggestTitle(String fileId) async =>
      _fallback.suggestTitle(fileId);

  @override
  Future<String> suggestFilename(String fileId) async =>
      _fallback.suggestFilename(fileId);

  @override
  Future<List<String>> getSuggestedCollections(String fileId) async =>
      _fallback.getSuggestedCollections(fileId);

  @override
  Future<bool> isModelLoaded() async => RustFfi.isAvailable;

  @override
  Future<List<AiModel>> getAvailableModels() async =>
      _fallback.getAvailableModels();

  @override
  Future<void> loadModel(String modelPath) async {}
}

class FfiSearchRepository implements SearchRepository {
  final SearchRepository _fallback = const StubSearchRepository();

  const FfiSearchRepository();

  @override
  Future<SearchResult> search(SearchQuery query) async {
    if (!RustFfi.isAvailable) return _fallback.search(query);
    try {
      final stopwatch = Stopwatch()..start();
      final jsonStr = RustFfi.search(query.text);
      final List decoded = jsonDecode(jsonStr);

      final hits = decoded
          .map((item) {
            final fileId = item['file_id'] ?? '';
            final fileJson = RustFfi.getFile(fileId);
            if (fileJson == 'null') return null;

            final fileMap = jsonDecode(fileJson);
            final fileEntry = FileEntry(
              id: fileMap['id'] ?? '',
              path: fileMap['path'] ?? '',
              filename: fileMap['filename'] ?? '',
              extension: fileMap['extension'] ?? '',
              fileType: FileType.fromExtension(fileMap['extension'] ?? ''),
              sizeBytes: fileMap['size_bytes'] ?? 0,
              createdAt: DateTime.tryParse(fileMap['created_at'] ?? '') ??
                  DateTime.now(),
              modifiedAt: DateTime.tryParse(fileMap['modified_at'] ?? '') ??
                  DateTime.now(),
            );

            return RankedFile(
              file: fileEntry,
              score: item['score'] ?? 0.0,
              matchSnippet: item['snippet'],
              matchType: SearchMatchType.ocrText,
            );
          })
          .whereType<RankedFile>()
          .toList();

      stopwatch.stop();
      return SearchResult(
        hits: hits,
        total: hits.length,
        elapsed: stopwatch.elapsed,
        query: query.text,
      );
    } catch (_) {
      return SearchResult(
          hits: [], total: 0, elapsed: Duration.zero, query: query.text);
    }
  }

  @override
  Future<List<String>> getSuggestions(String prefix) async =>
      _fallback.getSuggestions(prefix);

  @override
  Future<List<FileEntry>> findVisuallySimialar(String fileId) async =>
      _fallback.findVisuallySimialar(fileId);

  @override
  Future<List<FileEntry>> findByColor(String colorHex) async =>
      _fallback.findByColor(colorHex);
}

class FfiStorageRepository implements StorageRepository {
  final StorageRepository _fallback = const StubStorageRepository();

  const FfiStorageRepository();

  @override
  Future<StorageAnalysis> analyzeStorage() async {
    if (!RustFfi.isAvailable) return _fallback.analyzeStorage();
    try {
      final jsonStr = RustFfi.storageStats();
      final map = jsonDecode(jsonStr);
      return StorageAnalysis(
        totalBytes: map['total_bytes'] ?? 0,
        duplicateBytes: map['duplicate_bytes'] ?? 0,
        blurryCount: map['blurry_count'] ?? 0,
        emptyScreenshotCount: map['empty_screenshot_count'] ?? 0,
        largeFileCount: map['large_file_count'] ?? 0,
        recoverableBytes: map['recoverable_bytes'] ?? 0,
      );
    } catch (_) {
      return const StorageAnalysis(
        totalBytes: 0,
        duplicateBytes: 0,
        blurryCount: 0,
        emptyScreenshotCount: 0,
        largeFileCount: 0,
        recoverableBytes: 0,
      );
    }
  }

  @override
  Future<List<DuplicateGroup>> getDuplicateGroups() async =>
      _fallback.getDuplicateGroups();

  @override
  Future<List<SimilarGroup>> getSimilarImageGroups() async =>
      _fallback.getSimilarImageGroups();

  @override
  Future<StorageHeatmap> getHeatmap() async => _fallback.getHeatmap();

  @override
  Future<void> safeDelete(List<String> ids) async {
    if (RustFfi.isAvailable) {
      RustFfi.batchDelete(ids);
    }
  }

  @override
  Future<void> secureDelete(List<String> ids) async {
    if (RustFfi.isAvailable) {
      RustFfi.batchDelete(ids);
    }
  }
}

class FfiToolboxRepository implements ToolboxRepository {
  final ToolboxRepository _fallback = const StubToolboxRepository();

  const FfiToolboxRepository();

  @override
  Future<bool> convertDocument(String inputPath, String outputPath) async {
    if (!RustFfi.isAvailable) {
      return _fallback.convertDocument(inputPath, outputPath);
    }
    return RustFfi.convertDocument(inputPath, outputPath) == 0;
  }

  @override
  Future<bool> processImage(String inputPath, String outputPath, int width,
      int height, int quality) async {
    if (!RustFfi.isAvailable) {
      return _fallback.processImage(
          inputPath, outputPath, width, height, quality);
    }
    return RustFfi.processImage(
            inputPath, outputPath, width, height, quality) ==
        0;
  }

  @override
  Future<bool> normalizeWav(String inputPath, String outputPath) async {
    if (!RustFfi.isAvailable) {
      return _fallback.normalizeWav(inputPath, outputPath);
    }
    return RustFfi.normalizeWav(inputPath, outputPath) == 0;
  }

  @override
  Future<List<ArchiveItem>> listArchive(String archivePath) async {
    if (!RustFfi.isAvailable) {
      return _fallback.listArchive(archivePath);
    }
    try {
      final jsonStr = RustFfi.archiveList(archivePath);
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((item) => ArchiveItem.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> createArchive(String outputPath, List<String> paths) async {
    if (!RustFfi.isAvailable) {
      return _fallback.createArchive(outputPath, paths);
    }
    return RustFfi.archiveCreate(outputPath, paths) == 0;
  }

  @override
  Future<bool> extractArchive(String archivePath, String outputDir) async {
    if (!RustFfi.isAvailable) {
      return _fallback.extractArchive(archivePath, outputDir);
    }
    return RustFfi.archiveExtract(archivePath, outputDir) == 0;
  }

  @override
  Future<bool> performBackup(
      String dataDir, String backupPath, String keyPhrase) async {
    if (!RustFfi.isAvailable) {
      return _fallback.performBackup(dataDir, backupPath, keyPhrase);
    }
    return RustFfi.backupPerform(dataDir, backupPath, keyPhrase) == 0;
  }

  @override
  Future<bool> restoreBackup(
      String backupPath, String dataDir, String keyPhrase) async {
    if (!RustFfi.isAvailable) {
      return _fallback.restoreBackup(backupPath, dataDir, keyPhrase);
    }
    return RustFfi.backupRestore(backupPath, dataDir, keyPhrase) == 0;
  }
}
