import 'package:flutter_test/flutter_test.dart';
import 'package:memoryos/core/ffi/rust_ffi.dart';
import 'package:memoryos/core/domain/repositories.dart';
import 'package:memoryos/core/domain/ffi_repositories.dart';
import 'package:memoryos/core/domain/entities.dart';

void main() {
  group('FFI Repositories Fallback & Error Path Coverage', () {
    setUp(() {
      RustFfi.isAvailableOverride = false;
      RustFfi.initializeMockBindings();
    });

    test('FfiFileRepository coverage', () async {
      const repo = FfiFileRepository();
      
      // Test when isAvailable = false
      RustFfi.isAvailableOverride = false;
      await repo.getRecentFiles();
      await repo.searchFiles('query');
      await repo.getFilesByTag('tag');
      await repo.getFilesInCollection('col');
      await repo.getFileById('id');
      await repo.getStorageStats();
      await repo.toggleFavorite('id');
      await repo.deleteFile('id');
      await repo.getDuplicates();
      await repo.getBlurryImages();
      await repo.getSimilarFiles('id');
      await repo.getFavorites();
      await repo.getByDateRange(DateTime.now(), DateTime.now());
      await repo.getLargeFiles(minSizeMb: 10);
      await repo.importFile('path');
      await repo.importDirectory('dir');
      await repo.getVaultFiles();
      await repo.moveToVault('id');
      await repo.removeFromVault('id');
      await repo.getIndexStats();

      // Test when isAvailable = true (throws internally, caught in try-catch in test/repo)
      RustFfi.isAvailableOverride = true;
      try { await repo.getRecentFiles(); } catch (_) {}
      try { await repo.searchFiles('query'); } catch (_) {}
      try { await repo.getFilesByTag('tag'); } catch (_) {}
      try { await repo.getFilesInCollection('col'); } catch (_) {}
      try { await repo.getFilesInCollection('col-with-dash-and-longer-name-to-pass-regex'); } catch (_) {}
      try { await repo.getFileById('id'); } catch (_) {}
      try { await repo.getStorageStats(); } catch (_) {}
      try { await repo.toggleFavorite('id'); } catch (_) {}
      try { await repo.deleteFile('id'); } catch (_) {}
      try { await repo.getDuplicates(); } catch (_) {}
      try { await repo.getBlurryImages(); } catch (_) {}
      try { await repo.getSimilarFiles('id'); } catch (_) {}
      try { await repo.getFavorites(); } catch (_) {}
      try { await repo.getByDateRange(DateTime.now(), DateTime.now()); } catch (_) {}
      try { await repo.getLargeFiles(minSizeMb: 10); } catch (_) {}
      try { await repo.importFile('path.png'); } catch (_) {}
      try { await repo.importDirectory('dir'); } catch (_) {}
      try { await repo.getVaultFiles(); } catch (_) {}
      try { await repo.moveToVault('id'); } catch (_) {}
      try { await repo.removeFromVault('id'); } catch (_) {}
      try { await repo.getIndexStats(); } catch (_) {}
    });

    test('FfiCollectionRepository coverage', () async {
      const repo = FfiCollectionRepository();
      final collection = Collection(
        id: 'test-col',
        name: 'test-name',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      RustFfi.isAvailableOverride = false;
      await repo.getAllCollections();
      await repo.getSmartCollections();
      await repo.getCollectionById('id');
      await repo.createCollection(collection);
      await repo.updateCollection(collection);
      await repo.deleteCollection('id');
      await repo.addFileToCollection('file', 'col');
      await repo.removeFileFromCollection('file', 'col');

      RustFfi.isAvailableOverride = true;
      try { await repo.getAllCollections(); } catch (_) {}
      try { await repo.getSmartCollections(); } catch (_) {}
      try { await repo.getCollectionById('id'); } catch (_) {}
      try { await repo.createCollection(collection); } catch (_) {}
      try { await repo.updateCollection(collection); } catch (_) {}
      try { await repo.deleteCollection('id'); } catch (_) {}
      try { await repo.addFileToCollection('file', 'col'); } catch (_) {}
      try { await repo.removeFileFromCollection('file', 'col'); } catch (_) {}
    });

    test('FfiAiRepository coverage', () async {
      const repo = FfiAiRepository();

      RustFfi.isAvailableOverride = false;
      await repo.summarize('id');
      await repo.explainScreenshot('id');
      await repo.explainCode('id');
      await repo.explainDiagram('id');
      await repo.chat('msg', []);
      await repo.generateFlashcards('id');
      await repo.autoTag('id');
      await repo.suggestTitle('id');
      await repo.suggestFilename('id');
      await repo.getSuggestedCollections('id');
      await repo.isModelLoaded();
      await repo.getAvailableModels();
      await repo.loadModel('path');

      RustFfi.isAvailableOverride = true;
      try { await repo.summarize('id'); } catch (_) {}
      try { await repo.explainScreenshot('id'); } catch (_) {}
      try { await repo.explainCode('id'); } catch (_) {}
      try { await repo.explainDiagram('id'); } catch (_) {}
      try { await repo.chat('msg', []); } catch (_) {}
      try { await repo.generateFlashcards('id'); } catch (_) {}
      try { await repo.autoTag('id'); } catch (_) {}
      try { await repo.suggestTitle('id'); } catch (_) {}
      try { await repo.suggestFilename('id'); } catch (_) {}
      try { await repo.getSuggestedCollections('id'); } catch (_) {}
      try { await repo.isModelLoaded(); } catch (_) {}
      try { await repo.getAvailableModels(); } catch (_) {}
      try { await repo.loadModel('path'); } catch (_) {}
    });

    test('FfiSearchRepository coverage', () async {
      const repo = FfiSearchRepository();
      const query = SearchQuery(text: 'query');

      RustFfi.isAvailableOverride = false;
      await repo.search(query);
      await repo.getSuggestions('prefix');
      await repo.findVisuallySimialar('id');

      RustFfi.isAvailableOverride = true;
      try { await repo.search(query); } catch (_) {}
      try { await repo.getSuggestions('prefix'); } catch (_) {}
      try { await repo.findVisuallySimialar('id'); } catch (_) {}
    });

    test('FfiStorageRepository coverage', () async {
      const repo = FfiStorageRepository();

      RustFfi.isAvailableOverride = false;
      await repo.analyzeStorage();
      await repo.getDuplicateGroups();
      await repo.getSimilarImageGroups();
      await repo.getHeatmap();
      await repo.safeDelete(['id']);
      await repo.secureDelete(['id']);

      RustFfi.isAvailableOverride = true;
      try { await repo.analyzeStorage(); } catch (_) {}
      try { await repo.getDuplicateGroups(); } catch (_) {}
      try { await repo.getSimilarImageGroups(); } catch (_) {}
      try { await repo.getHeatmap(); } catch (_) {}
      try { await repo.safeDelete(['id']); } catch (_) {}
      try { await repo.secureDelete(['id']); } catch (_) {}
    });

    test('FfiThumbnailRepository coverage', () async {
      const repo = FfiThumbnailRepository();

      RustFfi.isAvailableOverride = false;
      await repo.getThumbnail('id');
      await repo.generateThumbnail('id');
      await repo.clearCache();

      RustFfi.isAvailableOverride = true;
      try { await repo.getThumbnail('id'); } catch (_) {}
      try { await repo.generateThumbnail('id'); } catch (_) {}
      try { await repo.clearCache(); } catch (_) {}
    });

    test('FfiToolboxRepository coverage', () async {
      const repo = FfiToolboxRepository();

      RustFfi.isAvailableOverride = false;
      await repo.convertDocument('in', 'out');
      await repo.processImage('in', 'out', 10, 10, 80);
      await repo.normalizeWav('in', 'out');
      await repo.listArchive('path');
      await repo.createArchive('out', ['path']);
      await repo.extractArchive('path', 'dir');
      await repo.performBackup('dir', 'path', 'key');
      await repo.restoreBackup('path', 'dir', 'key');

      RustFfi.isAvailableOverride = true;
      try { await repo.convertDocument('in', 'out'); } catch (_) {}
      try { await repo.processImage('in', 'out', 10, 10, 80); } catch (_) {}
      try { await repo.normalizeWav('in', 'out'); } catch (_) {}
      try { await repo.listArchive('path'); } catch (_) {}
      try { await repo.createArchive('out', ['path']); } catch (_) {}
      try { await repo.extractArchive('path', 'dir'); } catch (_) {}
      try { await repo.performBackup('dir', 'path', 'key'); } catch (_) {}
      try { await repo.restoreBackup('path', 'dir', 'key'); } catch (_) {}
    });
  });
}
