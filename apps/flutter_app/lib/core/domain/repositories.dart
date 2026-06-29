import 'package:memoryos/core/domain/entities.dart';

/// Abstract repository interface for file metadata operations.
abstract class FileRepository {
  Future<List<FileEntry>> getRecentFiles({int limit = 50, int offset = 0});
  Future<List<FileEntry>> searchFiles(String query, {String? typeFilter});
  Future<List<FileEntry>> getFilesByTag(String tagId);
  Future<List<FileEntry>> getFilesInCollection(String collectionId);
  Future<FileEntry?> getFileById(String id);
  Future<StorageStats> getStorageStats();
  Future<void> toggleFavorite(String id);
  Future<void> deleteFile(String id);
  Future<List<FileEntry>> getDuplicates();
}

/// Abstract repository interface for collection operations.
abstract class CollectionRepository {
  Future<List<Collection>> getAllCollections();
  Future<Collection?> getCollectionById(String id);
  Future<void> createCollection(Collection collection);
  Future<void> deleteCollection(String id);
}

/// Abstract repository interface for AI operations.
abstract class AiRepository {
  Future<String> summarize(String fileId);
  Future<String> chat(String message, List<Map<String, String>> history);
  Future<List<Map<String, String>>> generateFlashcards(String fileId);
  Future<List<String>> autoTag(String fileId);
}

/// Stub implementations — replaced by FFI calls to Rust once native
/// bridge initialization is complete.
class StubFileRepository implements FileRepository {
  const StubFileRepository();

  @override
  Future<List<FileEntry>> getRecentFiles({int limit = 50, int offset = 0}) async => [];

  @override
  Future<List<FileEntry>> searchFiles(String query, {String? typeFilter}) async => [];

  @override
  Future<List<FileEntry>> getFilesByTag(String tagId) async => [];

  @override
  Future<List<FileEntry>> getFilesInCollection(String collectionId) async => [];

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
}

class StubCollectionRepository implements CollectionRepository {
  const StubCollectionRepository();

  @override
  Future<List<Collection>> getAllCollections() async => [];

  @override
  Future<Collection?> getCollectionById(String id) async => null;

  @override
  Future<void> createCollection(Collection collection) async {}

  @override
  Future<void> deleteCollection(String id) async {}
}

class StubAiRepository implements AiRepository {
  const StubAiRepository();

  @override
  Future<String> summarize(String fileId) async =>
      'AI model not loaded. Download a model in Settings → AI Models.';

  @override
  Future<String> chat(String message, List<Map<String, String>> history) async =>
      'AI model not loaded. Download a model in Settings → AI Models.';

  @override
  Future<List<Map<String, String>>> generateFlashcards(String fileId) async => [];

  @override
  Future<List<String>> autoTag(String fileId) async => [];
}
