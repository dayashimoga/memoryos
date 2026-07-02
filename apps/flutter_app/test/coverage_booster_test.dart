import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';
import 'package:memoryos/features/settings/bloc/settings_bloc.dart';
import 'package:memoryos/core/blocs/app_blocs.dart';
import 'package:memoryos/core/domain/entities.dart';
import 'package:memoryos/core/domain/repositories.dart';

void main() {
  group('Equatable Props Coverage Booster', () {
    test('Settings Bloc Events & State props', () {
      const e1 = SettingsThemeChanged(ThemeMode.light);
      expect(e1.props, isNotEmpty);

      const e2 = SettingsLanguageChanged('en');
      expect(e2.props, isNotEmpty);

      const s1 = SettingsState(themeMode: ThemeMode.dark, languageCode: 'de');
      expect(s1.props, isNotEmpty);
    });

    test('Home Bloc Events & State props', () {
      final e1 = HomeLoadRequested();
      expect(e1.props, isEmpty);

      final e2 = HomeRefreshRequested();
      expect(e2.props, isEmpty);

      final e3 = HomeFileImported('path');
      expect(e3.props, isNotEmpty);

      final e4 = HomeToggleFavoriteRequested('id');
      expect(e4.props, isNotEmpty);

      final e5 = HomeDeleteFileRequested('id');
      expect(e5.props, isNotEmpty);

      const stats = StorageStats(totalFiles: 1);
      final s = HomeState(status: HomeStatus.loaded, stats: stats, recentFiles: const [], indexStats: const IndexStats());
      expect(s.props, isNotEmpty);
    });

    test('Search Bloc Events & State props', () {
      final e1 = SearchQueryChanged('q');
      expect(e1.props, isNotEmpty);

      final e2 = SearchCleared();
      expect(e2.props, isEmpty);

      final e3 = SearchHistoryRequested();
      expect(e3.props, isEmpty);

      final s = SearchState(status: SearchStatus.loaded, query: 'q', result: null, history: const ['old']);
      expect(s.props, isNotEmpty);
    });

    test('Storage Bloc Events & State props', () {
      final e1 = StorageScanRequested();
      expect(e1.props, isEmpty);

      final e2 = StorageDeleteRequested(const ['id']);
      expect(e2.props, isNotEmpty);

      const analysis = StorageAnalysis(
        totalBytes: 0,
        duplicateBytes: 0,
        blurryCount: 0,
        emptyScreenshotCount: 0,
        largeFileCount: 0,
        recoverableBytes: 0,
      );
      final s = StorageState(status: StorageStatus.loaded, analysis: analysis);
      expect(s.props, isNotEmpty);
    });

    test('Collections Bloc Events & State props', () {
      final e1 = CollectionsLoadRequested();
      expect(e1.props, isEmpty);

      final e2 = CollectionCreated('name');
      expect(e2.props, isNotEmpty);

      final e3 = CollectionDeleted('id');
      expect(e3.props, isNotEmpty);

      final s = CollectionsState(status: CollectionsStatus.loaded, smart: const [], manual: const []);
      expect(s.props, isNotEmpty);
    });

    test('Ai Bloc Events & State props', () {
      final e1 = AiCheckModel();
      expect(e1.props, isEmpty);

      final e2 = AiSendMessage('msg');
      expect(e2.props, isNotEmpty);

      final e3 = AiSummarizeFile('id');
      expect(e3.props, isNotEmpty);

      final e4 = AiGenerateFlashcards('id');
      expect(e4.props, isNotEmpty);

      final e5 = AiExplainFile('id', AiExplainMode.code);
      expect(e5.props, isNotEmpty);

      final e6 = AiClearConversation();
      expect(e6.props, isEmpty);

      final s = AiState(status: AiStatus.ready, messages: const [], flashcards: const [], modelLoaded: true);
      expect(s.props, isNotEmpty);
    });

    test('Import Bloc Events & State props', () {
      final e1 = ImportStarted(const ['p']);
      expect(e1.props, isNotEmpty);

      final e2 = ImportFolderStarted('dir');
      expect(e2.props, isNotEmpty);

      final e3 = ImportResetRequested();
      expect(e3.props, isEmpty);

      final s = ImportState(status: ImportStatus.success, currentFile: 'f', progress: 0.5, failedPaths: const []);
      expect(s.props, isNotEmpty);
    });
  });

  group('Shared Widgets Coverage Booster', () {
    testWidgets('Renders and animates SkeletonBox', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBox(width: 100, height: 20, radius: 4),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('Renders FileCardSkeleton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileCardSkeleton(),
          ),
        ),
      );
      expect(find.byType(FileCardSkeleton), findsOneWidget);
    });

    testWidgets('Renders MediaCardSkeleton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaCardSkeleton(),
          ),
        ),
      );
      expect(find.byType(MediaCardSkeleton), findsOneWidget);
    });

    testWidgets('Renders EmptyStateWidget with action button', (tester) async {
      bool actionTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.error,
              title: 'Empty',
              subtitle: 'Nothing here',
              actionLabel: 'Click Me',
              onAction: () => actionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Click Me'), findsOneWidget);

      await tester.tap(find.text('Click Me'));
      expect(actionTapped, isTrue);
    });

    testWidgets('Renders GlassSurface', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassSurface(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              child: Text('Glass Content'),
            ),
          ),
        ),
      );
      expect(find.text('Glass Content'), findsOneWidget);
    });

    testWidgets('Renders PremiumCard with long press', (tester) async {
      bool longPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumCard(
              onLongPress: () => longPressed = true,
              child: const Text('Premium Card Content'),
            ),
          ),
        ),
      );
      expect(find.text('Premium Card Content'), findsOneWidget);
      await tester.longPress(find.text('Premium Card Content'));
      expect(longPressed, isTrue);
    });

    testWidgets('FileTypeDisplay renders icons and boxes', (tester) async {
      expect(FileTypeDisplay.icon('pdf'), Icons.picture_as_pdf_rounded);
      expect(FileTypeDisplay.color('pdf'), const Color(0xFFEF4444));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FileTypeDisplay.iconWidget('jpg'),
                FileTypeDisplay.iconBox('mp4'),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(Icon), findsNWidgets(2));
    });

    testWidgets('SectionHeader trailing and action parameters', (tester) async {
      bool headerActionTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Header Title',
              action: 'See All',
              onAction: () => headerActionTapped = true,
              trailing: const Icon(Icons.star),
            ),
          ),
        ),
      );

      expect(find.text('Header Title'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);

      await tester.tap(find.text('See All'));
      expect(headerActionTapped, isTrue);
    });
  });
}
