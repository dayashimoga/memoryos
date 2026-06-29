import 'package:flutter_test/flutter_test.dart';
import 'package:memoryos/core/domain/entities.dart';
import 'package:memoryos/core/domain/repositories.dart';

void main() {
  group('StubFileRepository', () {
    const repo = StubFileRepository();

    test('getRecentFiles returns empty list', () async {
      final files = await repo.getRecentFiles();
      expect(files, isEmpty);
    });

    test('searchFiles returns empty list', () async {
      final files = await repo.searchFiles('test');
      expect(files, isEmpty);
    });

    test('getFileById returns null', () async {
      final file = await repo.getFileById('any-id');
      expect(file, isNull);
    });

    test('getStorageStats returns zeros', () async {
      final stats = await repo.getStorageStats();
      expect(stats.totalFiles, 0);
      expect(stats.totalSizeBytes, 0);
    });

    test('getDuplicates returns empty', () async {
      expect(await repo.getDuplicates(), isEmpty);
    });

    test('getFavorites returns empty', () async {
      expect(await repo.getFavorites(), isEmpty);
    });

    test('getIndexStats returns defaults', () async {
      final stats = await repo.getIndexStats();
      expect(stats.indexedFiles, 0);
      expect(stats.isRunning, false);
    });
  });

  group('StubCollectionRepository', () {
    const repo = StubCollectionRepository();

    test('getAllCollections returns empty', () async {
      expect(await repo.getAllCollections(), isEmpty);
    });

    test('getCollectionById returns null', () async {
      expect(await repo.getCollectionById('id'), isNull);
    });

    test('createCollection completes without error', () async {
      final now = DateTime.now();
      await repo.createCollection(Collection(
        id: 'x',
        name: 'Test',
        createdAt: now,
        updatedAt: now,
      ));
    });
  });

  group('StubAiRepository', () {
    const repo = StubAiRepository();

    test('summarize returns no-model message', () async {
      final summary = await repo.summarize('id');
      expect(summary, contains('No AI model'));
    });

    test('chat returns no-model message', () async {
      final reply = await repo.chat('hello', []);
      expect(reply, contains('No AI model'));
    });

    test('isModelLoaded returns false', () async {
      expect(await repo.isModelLoaded(), false);
    });

    test('getAvailableModels returns empty', () async {
      expect(await repo.getAvailableModels(), isEmpty);
    });

    test('generateFlashcards returns empty', () async {
      expect(await repo.generateFlashcards('id'), isEmpty);
    });

    test('autoTag returns empty', () async {
      expect(await repo.autoTag('id'), isEmpty);
    });
  });

  group('StubSearchRepository', () {
    const repo = StubSearchRepository();

    test('search returns empty result', () async {
      final result = await repo.search(const SearchQuery(text: 'test'));
      expect(result.isEmpty, true);
      expect(result.total, 0);
    });

    test('getSuggestions returns empty', () async {
      expect(await repo.getSuggestions('pre'), isEmpty);
    });
  });

  group('StubStorageRepository', () {
    const repo = StubStorageRepository();

    test('analyzeStorage returns zeros', () async {
      final analysis = await repo.analyzeStorage();
      expect(analysis.totalBytes, 0);
      expect(analysis.duplicateBytes, 0);
    });

    test('getDuplicateGroups returns empty', () async {
      expect(await repo.getDuplicateGroups(), isEmpty);
    });
  });

  group('StubToolboxRepository', () {
    const repo = StubToolboxRepository();

    test('convertDocument returns true', () async {
      expect(await repo.convertDocument('in', 'out'), true);
    });

    test('processImage returns true', () async {
      expect(await repo.processImage('in', 'out', 100, 100, 80), true);
    });

    test('listArchive returns empty', () async {
      expect(await repo.listArchive('test.zip'), isEmpty);
    });

    test('performBackup returns true', () async {
      expect(await repo.performBackup('/data', '/bak', 'key'), true);
    });
  });

  group('SearchQuery', () {
    test('default values', () {
      const q = SearchQuery(text: 'hello');
      expect(q.text, 'hello');
      expect(q.limit, 50);
      expect(q.offset, 0);
      expect(q.ranking, SearchRanking.relevance);
      expect(q.typeFilter, isNull);
    });
  });

  group('ArchiveItem', () {
    test('fromJson parses correctly', () {
      final item = ArchiveItem.fromJson({
        'name': 'file.txt',
        'size': 1024,
        'is_dir': false,
      });
      expect(item.name, 'file.txt');
      expect(item.size, 1024);
      expect(item.isDir, false);
    });

    test('fromJson handles missing fields', () {
      final item = ArchiveItem.fromJson({});
      expect(item.name, '');
      expect(item.size, 0);
      expect(item.isDir, false);
    });
  });
}
