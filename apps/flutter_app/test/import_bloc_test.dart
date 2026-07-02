import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:memoryos/core/blocs/app_blocs.dart';
import 'package:memoryos/core/domain/entities.dart';
import 'package:memoryos/core/domain/repositories.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockFileRepository extends Mock implements FileRepository {}

class MockStorageRepository extends Mock implements StorageRepository {}

class MockCollectionRepository extends Mock implements CollectionRepository {}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockFileRepository mockFileRepo;
  late HomeBloc homeBloc;

  setUp(() {
    mockFileRepo = MockFileRepository();
    // Stub required HomeBloc dependencies
    when(() => mockFileRepo.getStorageStats())
        .thenAnswer((_) async => const StorageStats());
    when(() => mockFileRepo.getRecentFiles(limit: any(named: 'limit'), offset: any(named: 'offset')))
        .thenAnswer((_) async => <FileEntry>[]);
    when(() => mockFileRepo.getIndexStats())
        .thenAnswer((_) async => const IndexStats());

    homeBloc = HomeBloc(mockFileRepo);
  });

  tearDown(() {
    homeBloc.close();
  });

  group('ImportBloc', () {
    blocTest<ImportBloc, ImportState>(
      'emits processing then success for single file import',
      build: () {
        when(() => mockFileRepo.importFile(any()))
            .thenAnswer((_) async {});
        return ImportBloc(mockFileRepo, homeBloc);
      },
      act: (bloc) => bloc.add(const ImportStarted(['/test/file.txt'])),
      expect: () => [
        // Processing start
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.processing)
            .having((s) => s.totalFiles, 'totalFiles', 1),
        // Validating stage
        isA<ImportState>()
            .having((s) => s.stage, 'stage', contains('Validating')),
        // Indexing stage
        isA<ImportState>()
            .having((s) => s.stage, 'stage', contains('Indexing')),
        // Processed count updated
        isA<ImportState>()
            .having((s) => s.processedFiles, 'processedFiles', 1),
        // Success
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.success)
            .having((s) => s.failedFiles, 'failedFiles', 0),
      ],
      verify: (_) {
        verify(() => mockFileRepo.importFile('/test/file.txt')).called(1);
      },
    );

    blocTest<ImportBloc, ImportState>(
      'tracks failed files when import throws',
      build: () {
        when(() => mockFileRepo.importFile(any()))
            .thenThrow(Exception('File corrupt'));
        return ImportBloc(mockFileRepo, homeBloc);
      },
      act: (bloc) =>
          bloc.add(const ImportStarted(['/test/corrupt.pdf'])),
      expect: () => [
        // Processing
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.processing),
        // Validating
        isA<ImportState>(),
        // Indexing
        isA<ImportState>(),
        // Failure tracked
        isA<ImportState>()
            .having((s) => s.failedFiles, 'failedFiles', 1)
            .having(
                (s) => s.failedPaths, 'failedPaths', contains('corrupt.pdf')),
        // Processed
        isA<ImportState>()
            .having((s) => s.processedFiles, 'processedFiles', 1),
        // Final state = failure since all files failed
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.failure)
            .having((s) => s.failedFiles, 'failedFiles', 1)
            .having((s) => s.error, 'error', isNotNull),
      ],
    );

    blocTest<ImportBloc, ImportState>(
      'partial success: some files succeed, some fail',
      build: () {
        var callCount = 0;
        when(() => mockFileRepo.importFile(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 2) throw Exception('Failed');
        });
        return ImportBloc(mockFileRepo, homeBloc);
      },
      act: (bloc) => bloc.add(const ImportStarted(
          ['/test/a.txt', '/test/b.txt', '/test/c.txt'])),
      expect: () => [
        // Processing
        isA<ImportState>()
            .having((s) => s.totalFiles, 'totalFiles', 3),
        // Multiple intermediate states...
        // Just check the final state
        ...List.generate(
            10, (_) => isA<ImportState>()), // intermediate states
        // Final: success with 1 failure
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.success)
            .having((s) => s.processedFiles, 'processedFiles', 3)
            .having((s) => s.failedFiles, 'failedFiles', 1),
      ],
    );

    blocTest<ImportBloc, ImportState>(
      'folder import dispatches importDirectory',
      build: () {
        when(() => mockFileRepo.importDirectory(any()))
            .thenAnswer((_) async => 5);
        return ImportBloc(mockFileRepo, homeBloc);
      },
      act: (bloc) =>
          bloc.add(const ImportFolderStarted('/test/folder')),
      expect: () => [
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.processing)
            .having((s) => s.stage, 'stage', 'Scanning directory...'),
        isA<ImportState>()
            .having((s) => s.status, 'status', ImportStatus.success)
            .having((s) => s.processedFiles, 'processedFiles', 5),
      ],
      verify: (_) {
        verify(() => mockFileRepo.importDirectory('/test/folder'))
            .called(1);
      },
    );

    blocTest<ImportBloc, ImportState>(
      'empty paths list does nothing',
      build: () => ImportBloc(mockFileRepo, homeBloc),
      act: (bloc) => bloc.add(const ImportStarted([])),
      expect: () => <ImportState>[],
    );

    blocTest<ImportBloc, ImportState>(
      'reset returns to idle state',
      build: () => ImportBloc(mockFileRepo, homeBloc),
      seed: () => const ImportState(
        status: ImportStatus.success,
        processedFiles: 5,
      ),
      act: (bloc) => bloc.add(ImportResetRequested()),
      expect: () => [const ImportState()],
    );
  });

  group('HomeBloc', () {
    blocTest<HomeBloc, HomeState>(
      'delete event calls deleteFile and refreshes',
      build: () {
        when(() => mockFileRepo.deleteFile(any()))
            .thenAnswer((_) async {});
        return HomeBloc(mockFileRepo);
      },
      act: (bloc) =>
          bloc.add(const HomeDeleteFileRequested('test-id')),
      expect: () => [
        // Refresh loading
        isA<HomeState>()
            .having((s) => s.status, 'status', HomeStatus.loading),
        // Loaded
        isA<HomeState>()
            .having((s) => s.status, 'status', HomeStatus.loaded),
      ],
      verify: (_) {
        verify(() => mockFileRepo.deleteFile('test-id')).called(1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'toggle favorite calls toggleFavorite and refreshes',
      build: () {
        when(() => mockFileRepo.toggleFavorite(any()))
            .thenAnswer((_) async {});
        return HomeBloc(mockFileRepo);
      },
      act: (bloc) =>
          bloc.add(const HomeToggleFavoriteRequested('test-id')),
      expect: () => [
        isA<HomeState>()
            .having((s) => s.status, 'status', HomeStatus.loading),
        isA<HomeState>()
            .having((s) => s.status, 'status', HomeStatus.loaded),
      ],
      verify: (_) {
        verify(() => mockFileRepo.toggleFavorite('test-id')).called(1);
      },
    );
  });
}
