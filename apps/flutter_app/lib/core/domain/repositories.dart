/// Expanded repository interfaces for v1.2 full integration.

import 'dart:typed_data';
import 'package:memoryos/core/domain/entities.dart';

// ─── File Repository ──────────────────────────────────────────────────────────

abstract class FileRepository {
  Future<List<FileEntry>> getRecentFiles({int limit = 50, int offset = 0});
  Future<List<FileEntry>> searchFiles(String query,
      {String? typeFilter, SearchRanking ranking = SearchRanking.relevance});
  Future<List<FileEntry>> getFilesByTag(String tagId);
  Future<List<FileEntry>> getFilesInCollection(String collectionId);
  Future<FileEntry?> getFileById(String id);
  Future<StorageStats> getStorageStats();
  Future<void> toggleFavorite(String id);
  Future<void> deleteFile(String id);
  Future<List<FileEntry>> getDuplicates();
  Future<List<FileEntry>> getBlurryImages();
  Future<List<FileEntry>> getLargeFiles({int minSizeMb = 50});
  Future<List<FileEntry>> getFavorites();
  Future<List<FileEntry>> getByDateRange(DateTime from, DateTime to);
  Future<List<FileEntry>> getSimilarFiles(String fileId);
  Future<void> importFile(String path);
  Future<void> batchDelete(List<String> ids);
  Future<void> batchTag(List<String> ids, List<String> tags);
  Future<void> batchMove(List<String> ids, String collectionId);
  Future<List<String>> getSearchHistory();
  Future<void> saveSearchQuery(String query);
  Future<IndexStats> getIndexStats();
}

// ─── Collection Repository ────────────────────────────────────────────────────

abstract class CollectionRepository {
  Future<List<Collection>> getAllCollections();
  Future<List<Collection>> getSmartCollections();
  Future<Collection?> getCollectionById(String id);
  Future<void> createCollection(Collection collection);
  Future<void> updateCollection(Collection collection);
  Future<void> deleteCollection(String id);
  Future<void> addFileToCollection(String fileId, String collectionId);
  Future<void> removeFileFromCollection(String fileId, String collectionId);
}

// ─── AI Repository ────────────────────────────────────────────────────────────

abstract class AiRepository {
  Future<String> summarize(String fileId);
  Future<String> explainScreenshot(String fileId);
  Future<String> explainCode(String fileId);
  Future<String> explainDiagram(String fileId);
  Future<String> chat(String message, List<ChatMessage> history);
  Future<List<Flashcard>> generateFlashcards(String fileId);
  Future<List<String>> autoTag(String fileId);
  Future<String> suggestTitle(String fileId);
  Future<String> suggestFilename(String fileId);
  Future<List<String>> getSuggestedCollections(String fileId);
  Future<bool> isModelLoaded();
  Future<List<AiModel>> getAvailableModels();
  Future<void> loadModel(String modelPath);
}

// ─── Search Repository ────────────────────────────────────────────────────────

abstract class SearchRepository {
  Future<SearchResult> search(SearchQuery query);
  Future<List<String>> getSuggestions(String prefix);
  Future<List<FileEntry>> findVisuallySimialar(String fileId);
  Future<List<FileEntry>> findByColor(String colorHex);
}

// ─── Storage Repository ───────────────────────────────────────────────────────

abstract class StorageRepository {
  Future<StorageAnalysis> analyzeStorage();
  Future<List<DuplicateGroup>> getDuplicateGroups();
  Future<List<SimilarGroup>> getSimilarImageGroups();
  Future<StorageHeatmap> getHeatmap();
  Future<void> safeDelete(List<String> ids);
  Future<void> secureDelete(List<String> ids);
}

// ─── Thumbnail Repository ─────────────────────────────────────────────────────

abstract class ThumbnailRepository {
  Future<Uint8List?> getThumbnail(String fileId, {int size = 256});
  Future<void> generateThumbnail(String fileId);
  Future<void> clearCache();
}

// ─── Domain value objects ─────────────────────────────────────────────────────

enum SearchRanking { relevance, date, size, name }

class SearchQuery {
  final String text;
  final String? typeFilter;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<String>? tags;
  final SearchRanking ranking;
  final int limit;
  final int offset;

  const SearchQuery({
    required this.text,
    this.typeFilter,
    this.fromDate,
    this.toDate,
    this.tags,
    this.ranking = SearchRanking.relevance,
    this.limit = 50,
    this.offset = 0,
  });
}

class SearchResult {
  final List<RankedFile> hits;
  final int total;
  final Duration elapsed;
  final String query;

  const SearchResult({
    required this.hits,
    required this.total,
    required this.elapsed,
    required this.query,
  });

  bool get isEmpty => hits.isEmpty;
}

class RankedFile {
  final FileEntry file;
  final double score;
  final String? matchSnippet;
  final SearchMatchType matchType;

  const RankedFile({
    required this.file,
    required this.score,
    this.matchSnippet,
    this.matchType = SearchMatchType.filename,
  });
}

enum SearchMatchType { filename, ocrText, summary, tag, metadata }

class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.content})
      : timestamp = DateTime.now();
}

class Flashcard {
  final String front;
  final String back;
  final String? sourceFileId;

  const Flashcard({required this.front, required this.back, this.sourceFileId});
}

class AiModel {
  final String id;
  final String name;
  final String provider;
  final double sizeGb;
  final bool isDownloaded;
  final bool isActive;

  const AiModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.sizeGb,
    required this.isDownloaded,
    required this.isActive,
  });
}

class IndexStats {
  final int indexedFiles;
  final int pendingFiles;
  final int failedFiles;
  final DateTime? lastIndexedAt;
  final bool isRunning;

  const IndexStats({
    this.indexedFiles = 0,
    this.pendingFiles = 0,
    this.failedFiles = 0,
    this.lastIndexedAt,
    this.isRunning = false,
  });
}

class StorageAnalysis {
  final int totalBytes;
  final int duplicateBytes;
  final int blurryCount;
  final int emptyScreenshotCount;
  final int largeFileCount;
  final int recoverableBytes;

  const StorageAnalysis({
    required this.totalBytes,
    required this.duplicateBytes,
    required this.blurryCount,
    required this.emptyScreenshotCount,
    required this.largeFileCount,
    required this.recoverableBytes,
  });
}

class DuplicateGroup {
  final String hash;
  final List<FileEntry> files;
  final int wastedBytes;

  const DuplicateGroup({
    required this.hash,
    required this.files,
    required this.wastedBytes,
  });
}

class SimilarGroup {
  final List<FileEntry> files;
  final double similarity;

  const SimilarGroup({required this.files, required this.similarity});
}

class StorageHeatmap {
  final Map<String, int> byExtension;
  final Map<String, int> byMonth;
  final Map<String, int> byCollection;

  const StorageHeatmap({
    required this.byExtension,
    required this.byMonth,
    required this.byCollection,
  });
}

// ─── Stub implementations (wire to FFI in production) ─────────────────────────

class StubFileRepository implements FileRepository {
  const StubFileRepository();
  @override
  Future<List<FileEntry>> getRecentFiles(
          {int limit = 50, int offset = 0}) async =>
      [];
  @override
  Future<List<FileEntry>> searchFiles(String q,
          {String? typeFilter,
          SearchRanking ranking = SearchRanking.relevance}) async =>
      [];
  @override
  Future<List<FileEntry>> getFilesByTag(String id) async => [];
  @override
  Future<List<FileEntry>> getFilesInCollection(String id) async => [];
  @override
  Future<FileEntry?> getFileById(String id) async => null;
  @override
  Future<StorageStats> getStorageStats() async => const StorageStats();
  @override
  Future<void> toggleFavorite(String id) async {}
  @override
  Future<void> deleteFile(String id) async {}
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
  Future<void> importFile(String path) async {}
  @override
  Future<void> batchDelete(List<String> ids) async {}
  @override
  Future<void> batchTag(List<String> ids, List<String> tags) async {}
  @override
  Future<void> batchMove(List<String> ids, String collectionId) async {}
  @override
  Future<List<String>> getSearchHistory() async => [];
  @override
  Future<void> saveSearchQuery(String query) async {}
  @override
  Future<IndexStats> getIndexStats() async => const IndexStats();
}

class StubCollectionRepository implements CollectionRepository {
  const StubCollectionRepository();
  @override
  Future<List<Collection>> getAllCollections() async => [];
  @override
  Future<List<Collection>> getSmartCollections() async => [];
  @override
  Future<Collection?> getCollectionById(String id) async => null;
  @override
  Future<void> createCollection(Collection c) async {}
  @override
  Future<void> updateCollection(Collection c) async {}
  @override
  Future<void> deleteCollection(String id) async {}
  @override
  Future<void> addFileToCollection(String fileId, String collId) async {}
  @override
  Future<void> removeFileFromCollection(String fileId, String collId) async {}
}

class StubAiRepository implements AiRepository {
  const StubAiRepository();
  @override
  Future<String> summarize(String id) async => _noModel;
  @override
  Future<String> explainScreenshot(String id) async => _noModel;
  @override
  Future<String> explainCode(String id) async => _noModel;
  @override
  Future<String> explainDiagram(String id) async => _noModel;
  @override
  Future<String> chat(String msg, List<ChatMessage> hist) async => _noModel;
  @override
  Future<List<Flashcard>> generateFlashcards(String id) async => [];
  @override
  Future<List<String>> autoTag(String id) async => [];
  @override
  Future<String> suggestTitle(String id) async => '';
  @override
  Future<String> suggestFilename(String id) async => '';
  @override
  Future<List<String>> getSuggestedCollections(String id) async => [];
  @override
  Future<bool> isModelLoaded() async => false;
  @override
  Future<List<AiModel>> getAvailableModels() async => [];
  @override
  Future<void> loadModel(String path) async {}
  static const _noModel =
      'No AI model loaded. Download one from Settings → AI Models.';
}

class StubSearchRepository implements SearchRepository {
  const StubSearchRepository();
  @override
  Future<SearchResult> search(SearchQuery query) async => SearchResult(
        hits: [],
        total: 0,
        elapsed: Duration.zero,
        query: query.text,
      );
  @override
  Future<List<String>> getSuggestions(String prefix) async => [];
  @override
  Future<List<FileEntry>> findVisuallySimialar(String id) async => [];
  @override
  Future<List<FileEntry>> findByColor(String hex) async => [];
}

class StubStorageRepository implements StorageRepository {
  const StubStorageRepository();
  @override
  Future<StorageAnalysis> analyzeStorage() async => const StorageAnalysis(
        totalBytes: 0,
        duplicateBytes: 0,
        blurryCount: 0,
        emptyScreenshotCount: 0,
        largeFileCount: 0,
        recoverableBytes: 0,
      );
  @override
  Future<List<DuplicateGroup>> getDuplicateGroups() async => [];
  @override
  Future<List<SimilarGroup>> getSimilarImageGroups() async => [];
  @override
  Future<StorageHeatmap> getHeatmap() async =>
      const StorageHeatmap(byExtension: {}, byMonth: {}, byCollection: {});
  @override
  Future<void> safeDelete(List<String> ids) async {}
  @override
  Future<void> secureDelete(List<String> ids) async {}
}

class StubThumbnailRepository implements ThumbnailRepository {
  const StubThumbnailRepository();
  @override
  Future<Uint8List?> getThumbnail(String id, {int size = 256}) async => null;
  @override
  Future<void> generateThumbnail(String id) async {}
  @override
  Future<void> clearCache() async {}
}

// ─── Toolbox Repository ───────────────────────────────────────────────────────

abstract class ToolboxRepository {
  Future<bool> convertDocument(String inputPath, String outputPath);
  Future<bool> processImage(
      String inputPath, String outputPath, int width, int height, int quality);
  Future<bool> normalizeWav(String inputPath, String outputPath);
  Future<List<ArchiveItem>> listArchive(String archivePath);
  Future<bool> createArchive(String outputPath, List<String> paths);
  Future<bool> extractArchive(String archivePath, String outputDir);
  Future<bool> performBackup(
      String dataDir, String backupPath, String keyPhrase);
  Future<bool> restoreBackup(
      String backupPath, String dataDir, String keyPhrase);
}

class ArchiveItem {
  final String name;
  final int size;
  final bool isDir;

  const ArchiveItem({
    required this.name,
    required this.size,
    required this.isDir,
  });

  factory ArchiveItem.fromJson(Map<String, dynamic> json) {
    return ArchiveItem(
      name: json['name'] ?? '',
      size: json['size'] ?? 0,
      isDir: json['is_dir'] ?? false,
    );
  }
}

class StubToolboxRepository implements ToolboxRepository {
  const StubToolboxRepository();

  @override
  Future<bool> convertDocument(String inputPath, String outputPath) async =>
      true;
  @override
  Future<bool> processImage(String inputPath, String outputPath, int width,
          int height, int quality) async =>
      true;
  @override
  Future<bool> normalizeWav(String inputPath, String outputPath) async => true;
  @override
  Future<List<ArchiveItem>> listArchive(String archivePath) async => [];
  @override
  Future<bool> createArchive(String outputPath, List<String> paths) async =>
      true;
  @override
  Future<bool> extractArchive(String archivePath, String outputDir) async =>
      true;
  @override
  Future<bool> performBackup(
          String dataDir, String backupPath, String keyPhrase) async =>
      true;
  @override
  Future<bool> restoreBackup(
          String backupPath, String dataDir, String keyPhrase) async =>
      true;
}
