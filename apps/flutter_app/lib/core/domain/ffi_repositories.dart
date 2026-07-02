import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:memoryos/core/di/service_locator.dart';
import 'package:memoryos/core/domain/entities.dart';
import 'package:memoryos/core/domain/repositories.dart';
import 'package:memoryos/core/ffi/rust_ffi.dart';

class FfiFileRepository implements FileRepository {
  final FileRepository _fallback = const StubFileRepository();

  const FfiFileRepository();

  static FileEntry parseFileEntry(Map<String, dynamic> map) {
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
      summary: map['summary'] as String?,
      ocrText: map['ocr_text'] as String?,
      phash: map['phash'] as String?,
      indexingStatus: map['indexing_status'] == 'Completed' ||
              map['indexing_status'] == '"Completed"'
          ? IndexingStatus.completed
          : map['indexing_status'] == 'Failed' ||
                  map['indexing_status'] == '"Failed"'
              ? IndexingStatus.failed
              : map['indexing_status'] == 'InProgress' ||
                      map['indexing_status'] == '"InProgress"'
                  ? IndexingStatus.indexing
                  : IndexingStatus.pending,
      isFavorite: map['is_favorite'] == true || map['is_favorite'] == 1,
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
      return decoded.map((item) => parseFileEntry(item)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<FileEntry>> searchFiles(String query,
      {String? typeFilter,
      SearchRanking ranking = SearchRanking.relevance}) async {
    if (!RustFfi.isAvailable) {
      return _fallback.searchFiles(query,
          typeFilter: typeFilter, ranking: ranking);
    }
    try {
      final jsonStr = RustFfi.searchFts(query);
      final List decoded = jsonDecode(jsonStr);
      final list = decoded.map((item) => parseFileEntry(item)).toList();

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
    if (!RustFfi.isAvailable)
      return _fallback.getFilesInCollection(collectionId);
    try {
      if (!collectionId.contains('-') && collectionId.length < 30) {
        final jsonStr = RustFfi.getFilesByCategory(collectionId);
        final List decoded = jsonDecode(jsonStr);
        return decoded.map((item) => parseFileEntry(item)).toList();
      }
      final jsonStr = RustFfi.getFilesInCollection(collectionId);
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((item) => parseFileEntry(item)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<FileEntry?> getFileById(String id) async {
    if (!RustFfi.isAvailable) return _fallback.getFileById(id);
    try {
      final jsonStr = RustFfi.getFile(id);
      if (jsonStr == 'null') return null;
      return parseFileEntry(jsonDecode(jsonStr));
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
  Future<void> toggleFavorite(String id) async {
    if (RustFfi.isAvailable) {
      RustFfi.toggleFavorite(id);
    }
  }

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
  Future<List<FileEntry>> getLargeFiles({int minSizeMb = 50}) async {
    if (!RustFfi.isAvailable) return [];
    try {
      final jsonStr = RustFfi.getLargeFiles(minSizeMb);
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((item) => parseFileEntry(item)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<FileEntry>> getFavorites() async {
    if (!RustFfi.isAvailable) return [];
    try {
      final jsonStr = RustFfi.listFavorites();
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((item) => parseFileEntry(item)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<FileEntry>> getByDateRange(DateTime from, DateTime to) async {
    if (!RustFfi.isAvailable) return [];
    try {
      final jsonStr = RustFfi.getTimeline(
          from.toUtc().toIso8601String(), to.toUtc().toIso8601String(), 100);
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((item) => parseFileEntry(item)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<FileEntry>> getSimilarFiles(String fileId) async => [];

  @override
  Future<void> importFile(String path) async {
    if (RustFfi.isAvailable) {
      final result = RustFfi.indexFile(path);
      // Auto-generate thumbnail for image files after successful import
      if (result == 0) {
        final ext = path.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
          try {
            final dir = await getApplicationDocumentsDirectory();
            final thumbDir = '${dir.path}/memoryos/thumbnails';
            await Directory(thumbDir).create(recursive: true);
            // Use filename hash as thumb key since we don't have the UUID here
            final thumbKey = path.hashCode.toRadixString(16);
            final thumbPath = '$thumbDir/$thumbKey.png';
            RustFfi.generateThumbnail(path, thumbPath, 256);
          } catch (_) {
            // Thumbnail generation is best-effort — don't fail the import
          }
        }
      }
    }
  }

  @override
  Future<int> importDirectory(String path) async {
    if (RustFfi.isAvailable) {
      return RustFfi.indexDirectory(path);
    }
    return 0;
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
  Future<List<String>> getSearchHistory() async {
    if (!RustFfi.isAvailable) return [];
    try {
      final jsonStr = RustFfi.getSearchHistory(10);
      final List decoded = jsonDecode(jsonStr);
      return List<String>.from(decoded);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveSearchQuery(String query) async {
    if (RustFfi.isAvailable) {
      RustFfi.saveSearchQuery(query, 0);
    }
  }

  @override
  Future<IndexStats> getIndexStats() async {
    if (!RustFfi.isAvailable) return const IndexStats();
    try {
      final jsonStr = RustFfi.getProcessingStatus();
      final map = jsonDecode(jsonStr);
      return IndexStats(
        indexedFiles: map['indexed_files'] ?? 0,
        pendingFiles: map['pending_count'] ?? 0,
        failedFiles: 0,
        isRunning: (map['pending_count'] ?? 0) > 0,
      );
    } catch (_) {
      return const IndexStats();
    }
  }

  @override
  Future<void> moveToVault(String id) async {
    if (RustFfi.isAvailable) {
      RustFfi.vaultAdd(id);
    }
  }

  @override
  Future<void> removeFromVault(String id) async {
    if (RustFfi.isAvailable) {
      RustFfi.vaultRemove(id);
    }
  }

  @override
  Future<List<FileEntry>> getVaultFiles() async {
    if (!RustFfi.isAvailable) return [];
    try {
      final jsonStr = RustFfi.vaultList();
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((item) => parseFileEntry(item)).toList();
    } catch (_) {
      return [];
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
      final jsonStr = RustFfi.searchFts(query.text);
      final List decoded = jsonDecode(jsonStr);

      final hits = decoded.map((item) {
        final fileEntry = FfiFileRepository.parseFileEntry(item);
        return RankedFile(
          file: fileEntry,
          score: 1.0, // FTS rank placeholder or score
          matchSnippet: fileEntry.ocrText ?? fileEntry.summary,
          matchType: SearchMatchType.ocrText,
        );
      }).toList();

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

class FfiCollectionRepository implements CollectionRepository {
  final CollectionRepository _fallback = const StubCollectionRepository();

  const FfiCollectionRepository();

  @override
  Future<List<Collection>> getAllCollections() async {
    if (!RustFfi.isAvailable) return _fallback.getAllCollections();
    try {
      final jsonStr = RustFfi.collectionList();
      final List decoded = jsonDecode(jsonStr);
      return decoded
          .map((item) => Collection(
                id: item['id'] ?? '',
                name: item['name'] ?? '',
                description: item['description'],
                fileCount: item['file_count'] ?? 0,
                createdAt: DateTime.tryParse(item['created_at'] ?? '') ??
                    DateTime.now(),
                updatedAt: DateTime.tryParse(item['updated_at'] ?? '') ??
                    DateTime.now(),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Collection>> getSmartCollections() async {
    if (!RustFfi.isAvailable) return _fallback.getSmartCollections();
    try {
      final jsonStr = RustFfi.listCategories();
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((item) {
        final name = item['name'] ?? 'Unknown';
        return Collection(
          id: name,
          name: name,
          description: 'Automatically categorized files',
          fileCount: item['file_count'] ?? 0,
          isSmart: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Collection?> getCollectionById(String id) async =>
      _fallback.getCollectionById(id);

  @override
  Future<void> createCollection(Collection collection) async {
    if (RustFfi.isAvailable) {
      RustFfi.collectionCreate(collection.name, collection.description ?? '');
    }
  }

  @override
  Future<void> updateCollection(Collection collection) async =>
      _fallback.updateCollection(collection);

  @override
  Future<void> deleteCollection(String id) async =>
      _fallback.deleteCollection(id);

  @override
  Future<void> addFileToCollection(String fileId, String collectionId) async {
    if (RustFfi.isAvailable) {
      RustFfi.collectionAddFile(collectionId, fileId);
    }
  }

  @override
  Future<void> removeFileFromCollection(String fileId, String collId) async =>
      _fallback.removeFileFromCollection(fileId, collId);
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
  Future<List<DuplicateGroup>> getDuplicateGroups() async {
    if (!RustFfi.isAvailable) return _fallback.getDuplicateGroups();
    try {
      final jsonStr = RustFfi.getDuplicateGroups();
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((group) {
        final List filesList = group['files'] ?? [];
        final files =
            filesList.map((f) => FfiFileRepository.parseFileEntry(f)).toList();
        return DuplicateGroup(
          hash: group['hash'] ?? '',
          files: files,
          wastedBytes: group['wasted_bytes'] ?? 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<SimilarGroup>> getSimilarImageGroups() async {
    if (!RustFfi.isAvailable) return _fallback.getSimilarImageGroups();
    try {
      final jsonStr = RustFfi.getSimilarGroups();
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((group) {
        final List filesList = group['files'] ?? [];
        final files =
            filesList.map((f) => FfiFileRepository.parseFileEntry(f)).toList();
        return SimilarGroup(
          files: files,
          similarity: group['similarity'] ?? 0.85,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

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

class FfiThumbnailRepository implements ThumbnailRepository {
  final ThumbnailRepository _fallback = const StubThumbnailRepository();

  const FfiThumbnailRepository();

  Future<String> _getThumbnailsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/memoryos/thumbnails';
    await Directory(path).create(recursive: true);
    return path;
  }

  @override
  Future<Uint8List?> getThumbnail(String fileId, {int size = 256}) async {
    if (!RustFfi.isAvailable) return _fallback.getThumbnail(fileId, size: size);
    try {
      final file = await ServiceLocator.fileRepo.getFileById(fileId);
      if (file == null) return null;

      // Only generate thumbnails for images
      if (file.fileType != FileType.image) return null;

      final thumbsDir = await _getThumbnailsDir();
      final thumbPath = '$thumbsDir/$fileId.png';
      final thumbFile = File(thumbPath);

      if (!await thumbFile.exists()) {
        final res = RustFfi.generateThumbnail(file.path, thumbPath, size);
        if (res != 0) return null;
      }

      return await thumbFile.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> generateThumbnail(String fileId) async {
    await getThumbnail(fileId);
  }

  @override
  Future<void> clearCache() async {
    try {
      final thumbsDir = await _getThumbnailsDir();
      final dir = Directory(thumbsDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
