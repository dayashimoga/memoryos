// Additional tests for MemoryOS Flutter application.
//
// Covers:
//   - HomeBloc (load, error, import events)
//   - SearchBloc (search, filter, clear, history)
//   - StorageBloc (scan, delete)
//   - CollectionsBloc (load, create, delete)
//   - AiBloc (model check, send message, summarize, flashcards, clear)
//   - Domain repository stubs (full coverage)
//   - SearchQuery and SearchResult value objects
//   - DuplicateGroup, SimilarGroup, StorageHeatmap
//   - FFI stub (all methods)

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:memoryos/core/blocs/app_blocs.dart';
import 'package:memoryos/core/domain/entities.dart';
import 'package:memoryos/core/domain/repositories.dart';
import 'package:memoryos/core/ffi/rust_ffi_stub.dart';

// ─── Mock Repositories ──────────────────────────────────────────────────────

class MockFileRepository extends Mock implements FileRepository {}

class MockSearchRepository extends Mock implements SearchRepository {}

class MockStorageRepository extends Mock implements StorageRepository {}

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockAiRepository extends Mock implements AiRepository {}

// ─── Helper fixtures ─────────────────────────────────────────────────────────

FileEntry _file({
  String id = 'f1',
  String ext = 'png',
  int size = 1024,
}) =>
    FileEntry(
      id: id,
      path: '/tmp/$id.$ext',
      filename: '$id.$ext',
      extension: ext,
      fileType: FileType.fromExtension(ext),
      sizeBytes: size,
      createdAt: DateTime(2024, 3, 1),
      modifiedAt: DateTime(2024, 3, 10),
    );

Collection _col({String id = 'c1', String name = 'Work'}) => Collection(
      id: id,
      name: name,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

// ─── HomeBloc Tests ──────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(_file());
    registerFallbackValue(_col());
    registerFallbackValue(const SearchQuery(text: 'x'));
    registerFallbackValue(<ChatMessage>[]);
    registerFallbackValue(<String>[]);
  });

  group('HomeBloc', () {
    late MockFileRepository fileRepo;

    setUp(() {
      fileRepo = MockFileRepository();
      when(() => fileRepo.getStorageStats())
          .thenAnswer((_) async => const StorageStats(totalFiles: 5));
      when(() => fileRepo.getRecentFiles(limit: 30))
          .thenAnswer((_) async => [_file(id: 'r1')]);
      when(() => fileRepo.getIndexStats())
          .thenAnswer((_) async => const IndexStats(indexedFiles: 5));
    });

    blocTest<HomeBloc, HomeState>(
      'emits loading then loaded on HomeLoadRequested',
      build: () => HomeBloc(fileRepo),
      act: (bloc) => bloc.add(HomeLoadRequested()),
      expect: () => [
        const HomeState(status: HomeStatus.loading),
        predicate<HomeState>((s) =>
            s.status == HomeStatus.loaded &&
            s.stats.totalFiles == 5 &&
            s.recentFiles.length == 1),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'emits error state when repository throws',
      build: () {
        when(() => fileRepo.getStorageStats()).thenThrow(Exception('DB error'));
        return HomeBloc(fileRepo);
      },
      act: (bloc) => bloc.add(HomeLoadRequested()),
      expect: () => [
        const HomeState(status: HomeStatus.loading),
        predicate<HomeState>(
            (s) => s.status == HomeStatus.error && s.error != null),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'HomeRefreshRequested triggers reload',
      build: () => HomeBloc(fileRepo),
      act: (bloc) => bloc.add(HomeRefreshRequested()),
      expect: () => [
        const HomeState(status: HomeStatus.loading),
        predicate<HomeState>((s) => s.status == HomeStatus.loaded),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'HomeFileImported calls importFile then reloads',
      build: () {
        when(() => fileRepo.importFile(any())).thenAnswer((_) async {});
        return HomeBloc(fileRepo);
      },
      act: (bloc) => bloc.add(const HomeFileImported('/tmp/photo.jpg')),
      verify: (_) {
        verify(() => fileRepo.importFile('/tmp/photo.jpg')).called(1);
      },
    );

    test('HomeState copyWith preserves fields', () {
      const original = HomeState(status: HomeStatus.loaded);
      final updated = original.copyWith(status: HomeStatus.error, error: 'e');
      expect(updated.status, HomeStatus.error);
      expect(updated.error, 'e');
      expect(updated.stats, original.stats);
    });
  });

  // ─── SearchBloc Tests ──────────────────────────────────────────────────────

  group('SearchBloc', () {
    late MockSearchRepository searchRepo;
    late MockFileRepository fileRepo;

    setUp(() {
      searchRepo = MockSearchRepository();
      fileRepo = MockFileRepository();
      when(() => searchRepo.search(any())).thenAnswer((_) async => SearchResult(
            hits: [RankedFile(file: _file(), score: 0.9)],
            total: 1,
            elapsed: const Duration(milliseconds: 5),
            query: 'test',
          ));
      when(() => fileRepo.saveSearchQuery(any())).thenAnswer((_) async {});
      when(() => fileRepo.getSearchHistory()).thenAnswer((_) async => ['old']);
    });

    blocTest<SearchBloc, SearchState>(
      'emits searching then loaded on SearchQueryChanged',
      build: () => SearchBloc(searchRepo, fileRepo),
      act: (bloc) => bloc.add(const SearchQueryChanged('test')),
      expect: () => [
        predicate<SearchState>((s) => s.status == SearchStatus.searching),
        predicate<SearchState>(
            (s) => s.status == SearchStatus.loaded && s.result != null),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'SearchCleared resets to idle state',
      build: () => SearchBloc(searchRepo, fileRepo),
      act: (bloc) {
        bloc.add(SearchCleared());
      },
      expect: () => [
        predicate<SearchState>(
            (s) => s.status == SearchStatus.idle && s.query.isEmpty),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'SearchHistoryRequested loads history',
      build: () => SearchBloc(searchRepo, fileRepo),
      act: (bloc) => bloc.add(SearchHistoryRequested()),
      expect: () => [
        predicate<SearchState>((s) => s.history.contains('old')),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'empty query emits idle immediately',
      build: () => SearchBloc(searchRepo, fileRepo),
      act: (bloc) => bloc.add(const SearchQueryChanged('')),
      expect: () => [
        predicate<SearchState>(
            (s) => s.status == SearchStatus.idle && s.query.isEmpty),
      ],
    );

    test('SearchState hasResults is false when result is null', () {
      const s = SearchState();
      expect(s.hasResults, isFalse);
    });
  });

  // ─── StorageBloc Tests ─────────────────────────────────────────────────────

  group('StorageBloc', () {
    late MockStorageRepository storageRepo;

    setUp(() {
      storageRepo = MockStorageRepository();
      when(() => storageRepo.analyzeStorage())
          .thenAnswer((_) async => const StorageAnalysis(
                totalBytes: 200 * 1024 * 1024,
                duplicateBytes: 50 * 1024 * 1024,
                blurryCount: 3,
                emptyScreenshotCount: 1,
                largeFileCount: 2,
                recoverableBytes: 60 * 1024 * 1024,
              ));
      when(() => storageRepo.getDuplicateGroups()).thenAnswer((_) async => []);
      when(() => storageRepo.getSimilarImageGroups())
          .thenAnswer((_) async => []);
      when(() => storageRepo.getHeatmap()).thenAnswer((_) async =>
          const StorageHeatmap(byExtension: {}, byMonth: {}, byCollection: {}));
      when(() => storageRepo.safeDelete(any())).thenAnswer((_) async {});
      when(() => storageRepo.secureDelete(any())).thenAnswer((_) async {});
    });

    blocTest<StorageBloc, StorageState>(
      'emits scanning then loaded on StorageScanRequested',
      build: () => StorageBloc(storageRepo),
      act: (bloc) => bloc.add(StorageScanRequested()),
      expect: () => [
        predicate<StorageState>((s) => s.status == StorageStatus.scanning),
        predicate<StorageState>((s) =>
            s.status == StorageStatus.loaded &&
            s.analysis!.duplicateBytes == 50 * 1024 * 1024),
      ],
    );

    blocTest<StorageBloc, StorageState>(
      'StorageDeleteRequested (safe) calls safeDelete',
      build: () => StorageBloc(storageRepo),
      act: (bloc) => bloc.add(const StorageDeleteRequested(['f1', 'f2'])),
      verify: (_) {
        verify(() => storageRepo.safeDelete(['f1', 'f2'])).called(1);
      },
    );

    blocTest<StorageBloc, StorageState>(
      'StorageDeleteRequested (secure) calls secureDelete',
      build: () => StorageBloc(storageRepo),
      act: (bloc) =>
          bloc.add(const StorageDeleteRequested(['f1'], secure: true)),
      verify: (_) {
        verify(() => storageRepo.secureDelete(['f1'])).called(1);
      },
    );

    test('StorageState totalRecoverableBytes is 0 when no analysis', () {
      const s = StorageState();
      expect(s.totalRecoverableBytes, 0);
    });
  });

  // ─── CollectionsBloc Tests ─────────────────────────────────────────────────

  group('CollectionsBloc', () {
    late MockCollectionRepository collRepo;

    setUp(() {
      collRepo = MockCollectionRepository();
      when(() => collRepo.getSmartCollections())
          .thenAnswer((_) async => [_col(id: 'smart1')]);
      when(() => collRepo.getAllCollections())
          .thenAnswer((_) async => [_col(id: 'c1'), _col(id: 'c2')]);
      when(() => collRepo.createCollection(any())).thenAnswer((_) async {});
      when(() => collRepo.deleteCollection(any())).thenAnswer((_) async {});
    });

    blocTest<CollectionsBloc, CollectionsState>(
      'emits loading then loaded on CollectionsLoadRequested',
      build: () => CollectionsBloc(collRepo),
      act: (bloc) => bloc.add(CollectionsLoadRequested()),
      expect: () => [
        predicate<CollectionsState>(
            (s) => s.status == CollectionsStatus.loading),
        predicate<CollectionsState>((s) =>
            s.status == CollectionsStatus.loaded &&
            s.manual.length == 2 &&
            s.smart.length == 1),
      ],
    );

    blocTest<CollectionsBloc, CollectionsState>(
      'CollectionCreated calls createCollection',
      build: () => CollectionsBloc(collRepo),
      act: (bloc) => bloc.add(const CollectionCreated('New Collection')),
      verify: (_) {
        verify(() => collRepo.createCollection(any())).called(1);
      },
    );

    blocTest<CollectionsBloc, CollectionsState>(
      'CollectionDeleted calls deleteCollection',
      build: () => CollectionsBloc(collRepo),
      act: (bloc) => bloc.add(const CollectionDeleted('c1')),
      verify: (_) {
        verify(() => collRepo.deleteCollection('c1')).called(1);
      },
    );
  });

  // ─── AiBloc Tests ─────────────────────────────────────────────────────────

  group('AiBloc', () {
    late MockAiRepository aiRepo;

    setUp(() {
      aiRepo = MockAiRepository();
      when(() => aiRepo.isModelLoaded()).thenAnswer((_) async => false);
      when(() => aiRepo.getAvailableModels()).thenAnswer((_) async => []);
      when(() => aiRepo.chat(any(), any()))
          .thenAnswer((_) async => 'Hello! How can I help?');
      when(() => aiRepo.summarize(any()))
          .thenAnswer((_) async => 'This is a summary.');
      when(() => aiRepo.generateFlashcards(any())).thenAnswer((_) async => [
            const Flashcard(
                front: 'Q: What is Dart?', back: 'A: A language by Google'),
          ]);
      when(() => aiRepo.explainScreenshot(any()))
          .thenAnswer((_) async => 'Screenshot shows...');
      when(() => aiRepo.explainCode(any()))
          .thenAnswer((_) async => 'Code does...');
      when(() => aiRepo.explainDiagram(any()))
          .thenAnswer((_) async => 'Diagram shows...');
    });

    blocTest<AiBloc, AiState>(
      'emits checking then noModel on AiCheckModel when no model loaded',
      build: () => AiBloc(aiRepo),
      act: (bloc) => bloc.add(AiCheckModel()),
      expect: () => [
        predicate<AiState>((s) => s.status == AiStatus.checking),
        predicate<AiState>(
            (s) => s.status == AiStatus.noModel && !s.modelLoaded),
      ],
    );

    blocTest<AiBloc, AiState>(
      'emits checking then ready when model is loaded',
      build: () {
        when(() => aiRepo.isModelLoaded()).thenAnswer((_) async => true);
        return AiBloc(aiRepo);
      },
      act: (bloc) => bloc.add(AiCheckModel()),
      expect: () => [
        predicate<AiState>((s) => s.status == AiStatus.checking),
        predicate<AiState>((s) => s.status == AiStatus.ready && s.modelLoaded),
      ],
    );

    blocTest<AiBloc, AiState>(
      'AiSendMessage appends user and assistant messages',
      build: () => AiBloc(aiRepo),
      seed: () => const AiState(status: AiStatus.noModel),
      act: (bloc) => bloc.add(const AiSendMessage('Hi')),
      expect: () => [
        predicate<AiState>(
            (s) => s.status == AiStatus.thinking && s.messages.length == 1),
        predicate<AiState>((s) =>
            s.status == AiStatus.ready &&
            s.messages.length == 2 &&
            s.messages.last.content == 'Hello! How can I help?'),
      ],
    );

    blocTest<AiBloc, AiState>(
      'AiSummarizeFile emits summary in lastSummary',
      build: () => AiBloc(aiRepo),
      act: (bloc) => bloc.add(const AiSummarizeFile('file-id')),
      expect: () => [
        predicate<AiState>((s) => s.status == AiStatus.thinking),
        predicate<AiState>((s) =>
            s.status == AiStatus.ready &&
            s.lastSummary == 'This is a summary.'),
      ],
    );

    blocTest<AiBloc, AiState>(
      'AiGenerateFlashcards emits flashcards',
      build: () => AiBloc(aiRepo),
      act: (bloc) => bloc.add(const AiGenerateFlashcards('file-id')),
      expect: () => [
        predicate<AiState>((s) => s.status == AiStatus.thinking),
        predicate<AiState>(
            (s) => s.status == AiStatus.ready && s.flashcards.length == 1),
      ],
    );

    blocTest<AiBloc, AiState>(
      'AiExplainFile (screenshot mode) emits summary',
      build: () => AiBloc(aiRepo),
      act: (bloc) =>
          bloc.add(const AiExplainFile('f1', AiExplainMode.screenshot)),
      expect: () => [
        predicate<AiState>((s) => s.status == AiStatus.thinking),
        predicate<AiState>((s) =>
            s.status == AiStatus.ready &&
            s.lastSummary!.contains('Screenshot')),
      ],
    );

    blocTest<AiBloc, AiState>(
      'AiExplainFile (code mode) emits summary',
      build: () => AiBloc(aiRepo),
      act: (bloc) => bloc.add(const AiExplainFile('f1', AiExplainMode.code)),
      expect: () => [
        predicate<AiState>((s) => s.status == AiStatus.thinking),
        predicate<AiState>((s) =>
            s.status == AiStatus.ready && s.lastSummary!.contains('Code')),
      ],
    );

    blocTest<AiBloc, AiState>(
      'AiExplainFile (diagram mode) emits summary',
      build: () => AiBloc(aiRepo),
      act: (bloc) => bloc.add(const AiExplainFile('f1', AiExplainMode.diagram)),
      expect: () => [
        predicate<AiState>((s) => s.status == AiStatus.thinking),
        predicate<AiState>((s) =>
            s.status == AiStatus.ready && s.lastSummary!.contains('Diagram')),
      ],
    );

    blocTest<AiBloc, AiState>(
      'AiClearConversation resets messages and flashcards',
      build: () => AiBloc(aiRepo),
      seed: () => AiState(
        status: AiStatus.ready,
        messages: [ChatMessage(role: 'user', content: 'hello')],
        flashcards: const [Flashcard(front: 'Q', back: 'A')],
      ),
      act: (bloc) => bloc.add(AiClearConversation()),
      expect: () => [
        predicate<AiState>((s) => s.messages.isEmpty && s.flashcards.isEmpty),
      ],
    );
  });

  // ─── Stub Repository Tests ─────────────────────────────────────────────────

  group('StubFileRepository', () {
    const repo = StubFileRepository();

    test('getRecentFiles returns empty list', () async {
      expect(await repo.getRecentFiles(), isEmpty);
    });
    test('searchFiles returns empty list', () async {
      expect(await repo.searchFiles('query'), isEmpty);
    });
    test('getStorageStats returns default stats', () async {
      final stats = await repo.getStorageStats();
      expect(stats.totalFiles, 0);
    });
    test('getDuplicates returns empty', () async {
      expect(await repo.getDuplicates(), isEmpty);
    });
    test('getBlurryImages returns empty', () async {
      expect(await repo.getBlurryImages(), isEmpty);
    });
    test('getLargeFiles returns empty', () async {
      expect(await repo.getLargeFiles(), isEmpty);
    });
    test('getFavorites returns empty', () async {
      expect(await repo.getFavorites(), isEmpty);
    });
    test('getByDateRange returns empty', () async {
      expect(
          await repo.getByDateRange(DateTime(2024), DateTime(2025)), isEmpty);
    });
    test('getSimilarFiles returns empty', () async {
      expect(await repo.getSimilarFiles('id'), isEmpty);
    });
    test('getFilesByTag returns empty', () async {
      expect(await repo.getFilesByTag('tag'), isEmpty);
    });
    test('getFilesInCollection returns empty', () async {
      expect(await repo.getFilesInCollection('cid'), isEmpty);
    });
    test('getFileById returns null', () async {
      expect(await repo.getFileById('id'), isNull);
    });
    test('getIndexStats returns defaults', () async {
      final idx = await repo.getIndexStats();
      expect(idx.indexedFiles, 0);
      expect(idx.isRunning, isFalse);
    });
    test('toggleFavorite completes without error', () async {
      await expectLater(repo.toggleFavorite('id'), completes);
    });
    test('deleteFile completes without error', () async {
      await expectLater(repo.deleteFile('id'), completes);
    });
    test('batchDelete completes without error', () async {
      await expectLater(repo.batchDelete(['a', 'b']), completes);
    });
    test('batchTag completes without error', () async {
      await expectLater(repo.batchTag(['a'], ['t']), completes);
    });
    test('batchMove completes without error', () async {
      await expectLater(repo.batchMove(['a'], 'cid'), completes);
    });
    test('importFile completes without error', () async {
      await expectLater(repo.importFile('/path/file.jpg'), completes);
    });
    test('getSearchHistory returns empty', () async {
      expect(await repo.getSearchHistory(), isEmpty);
    });
    test('saveSearchQuery completes', () async {
      await expectLater(repo.saveSearchQuery('q'), completes);
    });
  });

  group('StubAiRepository', () {
    const repo = StubAiRepository();

    test('isModelLoaded returns false', () async {
      expect(await repo.isModelLoaded(), isFalse);
    });
    test('getAvailableModels returns empty', () async {
      expect(await repo.getAvailableModels(), isEmpty);
    });
    test('summarize returns no model message', () async {
      final result = await repo.summarize('id');
      expect(result, contains('No AI model'));
    });
    test('explainScreenshot returns no model message', () async {
      expect(await repo.explainScreenshot('id'), contains('No AI model'));
    });
    test('explainCode returns no model message', () async {
      expect(await repo.explainCode('id'), contains('No AI model'));
    });
    test('explainDiagram returns no model message', () async {
      expect(await repo.explainDiagram('id'), contains('No AI model'));
    });
    test('chat returns no model message', () async {
      final result = await repo.chat('hi', []);
      expect(result, contains('No AI model'));
    });
    test('generateFlashcards returns empty', () async {
      expect(await repo.generateFlashcards('id'), isEmpty);
    });
    test('autoTag returns empty', () async {
      expect(await repo.autoTag('id'), isEmpty);
    });
    test('suggestTitle returns empty', () async {
      expect(await repo.suggestTitle('id'), isEmpty);
    });
    test('suggestFilename returns empty', () async {
      expect(await repo.suggestFilename('id'), isEmpty);
    });
    test('getSuggestedCollections returns empty', () async {
      expect(await repo.getSuggestedCollections('id'), isEmpty);
    });
    test('loadModel completes', () async {
      await expectLater(repo.loadModel('/path/model.gguf'), completes);
    });
  });

  group('StubSearchRepository', () {
    const repo = StubSearchRepository();

    test('search returns empty result', () async {
      final result = await repo.search(const SearchQuery(text: 'hello'));
      expect(result.isEmpty, isTrue);
      expect(result.total, 0);
      expect(result.query, 'hello');
    });
    test('getSuggestions returns empty', () async {
      expect(await repo.getSuggestions('h'), isEmpty);
    });
    test('findVisuallySimialar returns empty', () async {
      expect(await repo.findVisuallySimialar('id'), isEmpty);
    });
    test('findByColor returns empty', () async {
      expect(await repo.findByColor('#FF0000'), isEmpty);
    });
  });

  group('StubStorageRepository', () {
    const repo = StubStorageRepository();

    test('analyzeStorage returns zero bytes', () async {
      final analysis = await repo.analyzeStorage();
      expect(analysis.totalBytes, 0);
    });
    test('getDuplicateGroups returns empty', () async {
      expect(await repo.getDuplicateGroups(), isEmpty);
    });
    test('getSimilarImageGroups returns empty', () async {
      expect(await repo.getSimilarImageGroups(), isEmpty);
    });
    test('getHeatmap returns empty maps', () async {
      final hm = await repo.getHeatmap();
      expect(hm.byExtension, isEmpty);
    });
    test('safeDelete completes', () async {
      await expectLater(repo.safeDelete(['x']), completes);
    });
    test('secureDelete completes', () async {
      await expectLater(repo.secureDelete(['x']), completes);
    });
  });

  group('StubThumbnailRepository', () {
    const repo = StubThumbnailRepository();

    test('getThumbnail returns null', () async {
      expect(await repo.getThumbnail('id'), isNull);
    });
    test('generateThumbnail completes', () async {
      await expectLater(repo.generateThumbnail('id'), completes);
    });
    test('clearCache completes', () async {
      await expectLater(repo.clearCache(), completes);
    });
  });

  group('StubCollectionRepository', () {
    const repo = StubCollectionRepository();

    test('getAllCollections returns empty', () async {
      expect(await repo.getAllCollections(), isEmpty);
    });
    test('getSmartCollections returns empty', () async {
      expect(await repo.getSmartCollections(), isEmpty);
    });
    test('getCollectionById returns null', () async {
      expect(await repo.getCollectionById('id'), isNull);
    });
    test('createCollection completes', () async {
      await expectLater(repo.createCollection(_col()), completes);
    });
    test('updateCollection completes', () async {
      await expectLater(repo.updateCollection(_col()), completes);
    });
    test('deleteCollection completes', () async {
      await expectLater(repo.deleteCollection('id'), completes);
    });
    test('addFileToCollection completes', () async {
      await expectLater(repo.addFileToCollection('fid', 'cid'), completes);
    });
    test('removeFileFromCollection completes', () async {
      await expectLater(repo.removeFileFromCollection('fid', 'cid'), completes);
    });
  });

  group('StubToolboxRepository', () {
    const repo = StubToolboxRepository();

    test('convertDocument returns true', () async {
      expect(await repo.convertDocument('a', 'b'), isTrue);
    });
    test('processImage returns true', () async {
      expect(await repo.processImage('a', 'b', 1, 1, 1), isTrue);
    });
    test('normalizeWav returns true', () async {
      expect(await repo.normalizeWav('a', 'b'), isTrue);
    });
    test('listArchive returns empty', () async {
      expect(await repo.listArchive('a'), isEmpty);
    });
    test('createArchive returns true', () async {
      expect(await repo.createArchive('a', []), isTrue);
    });
    test('extractArchive returns true', () async {
      expect(await repo.extractArchive('a', 'b'), isTrue);
    });
    test('performBackup returns true', () async {
      expect(await repo.performBackup('a', 'b', 'c'), isTrue);
    });
    test('restoreBackup returns true', () async {
      expect(await repo.restoreBackup('a', 'b', 'c'), isTrue);
    });
  });

  // ─── SearchQuery / SearchResult ────────────────────────────────────────────

  group('SearchQuery', () {
    test('defaults are correct', () {
      const q = SearchQuery(text: 'notes');
      expect(q.text, 'notes');
      expect(q.ranking, SearchRanking.relevance);
      expect(q.limit, 50);
      expect(q.offset, 0);
      expect(q.typeFilter, isNull);
      expect(q.tags, isNull);
    });

    test('all fields can be set', () {
      final q = SearchQuery(
        text: 'code',
        typeFilter: 'dart',
        fromDate: DateTime(2024, 1),
        toDate: DateTime(2024, 12),
        tags: ['flutter'],
        ranking: SearchRanking.date,
        limit: 20,
        offset: 5,
      );
      expect(q.ranking, SearchRanking.date);
      expect(q.limit, 20);
      expect(q.offset, 5);
      expect(q.tags, contains('flutter'));
    });
  });

  group('SearchResult', () {
    test('isEmpty is true when no hits', () {
      final r =
          SearchResult(hits: [], total: 0, elapsed: Duration.zero, query: 'x');
      expect(r.isEmpty, isTrue);
    });

    test('isEmpty is false when hits present', () {
      final r = SearchResult(
        hits: [RankedFile(file: _file(), score: 1.0)],
        total: 1,
        elapsed: const Duration(milliseconds: 3),
        query: 'test',
      );
      expect(r.isEmpty, isFalse);
    });
  });

  group('RankedFile', () {
    test('has score and optional snippet', () {
      final rf = RankedFile(
        file: _file(),
        score: 0.75,
        matchSnippet: 'some text match',
        matchType: SearchMatchType.ocrText,
      );
      expect(rf.score, closeTo(0.75, 0.001));
      expect(rf.matchSnippet, 'some text match');
      expect(rf.matchType, SearchMatchType.ocrText);
    });
  });

  group('DuplicateGroup', () {
    test('holds files and wastedBytes', () {
      final group = DuplicateGroup(
        hash: 'abc123',
        files: [_file(id: 'f1'), _file(id: 'f2')],
        wastedBytes: 2048,
      );
      expect(group.files.length, 2);
      expect(group.wastedBytes, 2048);
    });
  });

  group('SimilarGroup', () {
    test('holds similarity score', () {
      final g = SimilarGroup(
        files: [_file(id: 'a'), _file(id: 'b')],
        similarity: 0.87,
      );
      expect(g.similarity, closeTo(0.87, 0.001));
    });
  });

  group('StorageHeatmap', () {
    test('holds extension map', () {
      const hm = StorageHeatmap(
        byExtension: {'png': 100, 'pdf': 50},
        byMonth: {'2024-01': 20},
        byCollection: {'Work': 30},
      );
      expect(hm.byExtension['png'], 100);
      expect(hm.byMonth['2024-01'], 20);
      expect(hm.byCollection['Work'], 30);
    });
  });

  // ─── FFI Stub Tests ────────────────────────────────────────────────────────

  group('RustFfi (stub)', () {
    test('isAvailable is false', () {
      expect(RustFfi.isAvailable, isFalse);
    });
    test('getVersion returns stub version string', () {
      expect(RustFfi.getVersion(), contains('stub'));
    });
    test('countFiles returns 0', () {
      expect(RustFfi.countFiles(), 0);
    });
    test('listFiles returns empty JSON array', () {
      expect(RustFfi.listFiles(10, 0), '[]');
    });
    test('getFile returns null string', () {
      expect(RustFfi.getFile('id'), 'null');
    });
    test('search returns empty JSON array', () {
      expect(RustFfi.search('query'), '[]');
    });
    test('storageStats returns empty JSON object', () {
      expect(RustFfi.storageStats(), '{}');
    });
    test('indexFile returns -1', () {
      expect(RustFfi.indexFile('/path/to/file'), -1);
    });
    test('batchDelete returns 0', () {
      expect(RustFfi.batchDelete(['a', 'b']), 0);
    });
    test('vaultAdd returns -1', () {
      expect(RustFfi.vaultAdd('id'), -1);
    });
    test('vaultRemove returns -1', () {
      expect(RustFfi.vaultRemove('id'), -1);
    });
    test('vaultList returns empty array', () {
      expect(RustFfi.vaultList(), '[]');
    });
    test('tagList returns empty array', () {
      expect(RustFfi.tagList(), '[]');
    });
    test('tagCreate returns -1', () {
      expect(RustFfi.tagCreate('name', '#FF0000'), -1);
    });
    test('tagFile returns -1', () {
      expect(RustFfi.tagFile('fid', 'tid'), -1);
    });
    test('collectionList returns empty array', () {
      expect(RustFfi.collectionList(), '[]');
    });
    test('collectionCreate returns -1', () {
      expect(RustFfi.collectionCreate('name', 'desc'), -1);
    });
    test('collectionAddFile returns -1', () {
      expect(RustFfi.collectionAddFile('cid', 'fid'), -1);
    });
    test('getDuplicateGroups returns empty array', () {
      expect(RustFfi.getDuplicateGroups(), '[]');
    });
    test('getSimilarGroups returns empty array', () {
      expect(RustFfi.getSimilarGroups(), '[]');
    });
    test('recentFiles returns empty array', () {
      expect(RustFfi.recentFiles(10), '[]');
    });
    test('getLargeFiles returns empty array', () {
      expect(RustFfi.getLargeFiles(50), '[]');
    });
    test('hashFile returns -1', () {
      expect(RustFfi.hashFile('id'), -1);
    });
    test('convertDocument returns -1', () {
      expect(RustFfi.convertDocument('a', 'b'), -1);
    });
    test('processImage returns -1', () {
      expect(RustFfi.processImage('a', 'b', 800, 600, 90), -1);
    });
    test('normalizeWav returns -1', () {
      expect(RustFfi.normalizeWav('a', 'b'), -1);
    });
    test('archiveList returns empty array', () {
      expect(RustFfi.archiveList('path'), '[]');
    });
    test('archiveCreate returns -1', () {
      expect(RustFfi.archiveCreate('path', []), -1);
    });
    test('archiveExtract returns -1', () {
      expect(RustFfi.archiveExtract('path', 'dest'), -1);
    });
    test('backupPerform returns -1', () {
      expect(RustFfi.backupPerform('/data', '/backup.enc', 'pwd'), -1);
    });
    test('backupRestore returns -1', () {
      expect(RustFfi.backupRestore('/backup.enc', '/data', 'pwd'), -1);
    });
    test('init returns -1', () {
      expect(RustFfi.init('/data/dir'), -1);
    });
    test('isInitialized returns false', () {
      expect(RustFfi.isInitialized(), isFalse);
    });
    test('initialize runs without error', () {
      expect(() => RustFfi.initialize(), returnsNormally);
    });
  });

  // ─── Value Objects ─────────────────────────────────────────────────────────

  group('IndexStats', () {
    test('defaults are all zero/false', () {
      const s = IndexStats();
      expect(s.indexedFiles, 0);
      expect(s.pendingFiles, 0);
      expect(s.failedFiles, 0);
      expect(s.isRunning, isFalse);
      expect(s.lastIndexedAt, isNull);
    });
  });

  group('ChatMessage', () {
    test('has role, content, and timestamp', () {
      final msg = ChatMessage(role: 'user', content: 'Hello');
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
      expect(msg.timestamp, isA<DateTime>());
    });
  });

  group('Flashcard', () {
    test('has front, back and optional sourceFileId', () {
      const card = Flashcard(
          front: 'What is FFI?',
          back: 'Foreign Function Interface',
          sourceFileId: 'f1');
      expect(card.front, 'What is FFI?');
      expect(card.sourceFileId, 'f1');
    });
  });

  group('AiModel', () {
    test('holds all properties', () {
      const m = AiModel(
        id: 'gemma-2b',
        name: 'Gemma 2B',
        provider: 'Google',
        sizeGb: 1.5,
        isDownloaded: true,
        isActive: false,
      );
      expect(m.id, 'gemma-2b');
      expect(m.sizeGb, 1.5);
      expect(m.isDownloaded, isTrue);
      expect(m.isActive, isFalse);
    });
  });

  group('ArchiveItem', () {
    test('parses from JSON correctly', () {
      final item = ArchiveItem.fromJson({
        'name': 'readme.txt',
        'size': 512,
        'is_dir': false,
      });
      expect(item.name, 'readme.txt');
      expect(item.size, 512);
      expect(item.isDir, isFalse);
    });

    test('handles missing fields with defaults', () {
      final item = ArchiveItem.fromJson({});
      expect(item.name, isEmpty);
      expect(item.size, 0);
      expect(item.isDir, isFalse);
    });
  });
}
