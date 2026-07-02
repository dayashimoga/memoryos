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

    test('remaining stub file repository methods', () async {
      expect(await repo.importDirectory('/dir'), 0);
      await repo.moveToVault('id');
      await repo.removeFromVault('id');
      expect(await repo.getVaultFiles(), isEmpty);
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

  group('Remaining Value Objects & Stub Repositories', () {
    test('SearchResult isNotEmpty check', () {
      final fileEntry = FileEntry(
        id: 'f1', path: '/tmp/f1', filename: 'f1', extension: 'png', fileType: FileType.image,
        sizeBytes: 100, createdAt: DateTime.now(), modifiedAt: DateTime.now(),
      );
      final res = SearchResult(
        hits: [RankedFile(file: fileEntry, score: 1.0, matchSnippet: 'snippet', matchType: SearchMatchType.filename)],
        total: 1,
        elapsed: Duration.zero,
        query: 'q',
      );
      expect(res.isEmpty, isFalse);
    });

    test('ChatMessage properties', () {
      final msg = ChatMessage(role: 'user', content: 'hello');
      expect(msg.role, 'user');
      expect(msg.content, 'hello');
      expect(msg.timestamp, isNotNull);
    });

    test('Flashcard properties', () {
      const fc = Flashcard(front: 'Q', back: 'A', sourceFileId: 'fid');
      expect(fc.sourceFileId, 'fid');
    });

    test('AiModel properties', () {
      const model = AiModel(id: 'm', name: 'model', provider: 'google', sizeGb: 1.5, isDownloaded: true, isActive: true);
      expect(model.id, 'm');
      expect(model.name, 'model');
      expect(model.provider, 'google');
      expect(model.sizeGb, 1.5);
      expect(model.isDownloaded, isTrue);
      expect(model.isActive, isTrue);
    });

    test('IndexStats properties', () {
      final stats = IndexStats(indexedFiles: 1, pendingFiles: 2, failedFiles: 3, lastIndexedAt: DateTime.now(), isRunning: true);
      expect(stats.indexedFiles, 1);
      expect(stats.pendingFiles, 2);
      expect(stats.failedFiles, 3);
      expect(stats.lastIndexedAt, isNotNull);
      expect(stats.isRunning, isTrue);
    });

    test('StubSearchRepository remaining methods', () async {
      const repo = StubSearchRepository();
      expect(await repo.findByColor('hex'), isEmpty);
      expect(await repo.findVisuallySimialar('id'), isEmpty);
    });

    test('StubStorageRepository remaining methods', () async {
      const repo = StubStorageRepository();
      expect(await repo.getSimilarImageGroups(), isEmpty);
      expect(await repo.getHeatmap(), isNotNull);
      await repo.safeDelete(['id']);
      await repo.secureDelete(['id']);
    });

    test('StubThumbnailRepository remaining methods', () async {
      const repo = StubThumbnailRepository();
      expect(await repo.getThumbnail('id'), isNull);
      await repo.generateThumbnail('id');
      await repo.clearCache();
    });
  });
}
