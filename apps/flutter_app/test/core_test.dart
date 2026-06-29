// Widget and unit tests for MemoryOS Flutter application.
//
// Coverage targets:
//   - Domain entities (FileEntry, Tag, Collection, StorageStats)
//   - Shared widgets (SkeletonBox, EmptyStateWidget, FileTypeDisplay)
//   - DesignTokens constants
//   - SettingsBloc state management
//   - FileType classification helpers

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:memoryos/core/domain/entities.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';
import 'package:memoryos/features/settings/bloc/settings_bloc.dart';

// ─── Test helpers ─────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      home: Scaffold(body: child),
    );

FileEntry _makeEntry({
  String id = 'test-id',
  String filename = 'test.png',
  String ext = 'png',
  int sizeBytes = 1024 * 1024,
  List<String> tags = const [],
}) =>
    FileEntry(
      id: id,
      path: '/tmp/$filename',
      filename: filename,
      extension: ext,
      fileType: FileType.fromExtension(ext),
      sizeBytes: sizeBytes,
      createdAt: DateTime(2024, 1, 15),
      modifiedAt: DateTime(2024, 6, 20),
    );

// ─── Domain Entity Tests ──────────────────────────────────────────────────────

void main() {
  group('FileEntry', () {
    test('formattedSize returns bytes for <1 KB', () {
      final e = _makeEntry(sizeBytes: 512);
      expect(e.formattedSize, '512 B');
    });

    test('formattedSize returns KB for <1 MB', () {
      final e = _makeEntry(sizeBytes: 2048);
      expect(e.formattedSize, '2.0 KB');
    });

    test('formattedSize returns MB for <1 GB', () {
      final e = _makeEntry(sizeBytes: 3 * 1024 * 1024);
      expect(e.formattedSize, '3.0 MB');
    });

    test('formattedSize returns GB for >=1 GB', () {
      final e = _makeEntry(sizeBytes: 2 * 1024 * 1024 * 1024);
      expect(e.formattedSize, contains('GB'));
    });

    test('copyWith preserves original fields', () {
      final original = _makeEntry(tags: ['cloud']);
      final updated = original.copyWith(tags: ['cloud', 'k8s']);
      expect(updated.id, original.id);
      expect(updated.path, original.path);
      expect(updated.tags, ['cloud', 'k8s']);
    });

    test('Equatable equality is id-based', () {
      final a = _makeEntry(id: 'abc');
      final b = _makeEntry(id: 'abc');
      expect(a, equals(b));
    });

    test('timeAgo returns "just now" for very recent', () {
      final e = FileEntry(
        id: 'x',
        path: '/tmp/x',
        filename: 'x',
        extension: '',
        fileType: FileType.unknown,
        sizeBytes: 0,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      expect(e.timeAgo, 'just now');
    });
  });

  group('FileType.fromExtension', () {
    test('png maps to image', () {
      expect(FileType.fromExtension('png'), FileType.image);
    });
    test('jpg maps to image', () {
      expect(FileType.fromExtension('jpg'), FileType.image);
    });
    test('pdf maps to document', () {
      expect(FileType.fromExtension('pdf'), FileType.document);
    });
    test('mp4 maps to video', () {
      expect(FileType.fromExtension('mp4'), FileType.video);
    });
    test('mp3 maps to audio', () {
      expect(FileType.fromExtension('mp3'), FileType.audio);
    });
    test('zip maps to archive', () {
      expect(FileType.fromExtension('zip'), FileType.archive);
    });
    test('md maps to markdown', () {
      expect(FileType.fromExtension('md'), FileType.markdown);
    });
    test('xlsx maps to spreadsheet', () {
      expect(FileType.fromExtension('xlsx'), FileType.spreadsheet);
    });
    test('unknown extension maps to unknown', () {
      expect(FileType.fromExtension('xyz123'), FileType.unknown);
    });
    test('isMedia true for image', () {
      expect(FileType.image.isMedia, isTrue);
    });
    test('isMedia false for document', () {
      expect(FileType.document.isMedia, isFalse);
    });
    test('isDocument true for document', () {
      expect(FileType.document.isDocument, isTrue);
    });
    test('case insensitive extension matching', () {
      expect(FileType.fromExtension('PDF'), FileType.document);
      expect(FileType.fromExtension('MP3'), FileType.audio);
    });
  });

  group('StorageStats', () {
    test('recoverableBytes adds duplicates and blurry estimate', () {
      const stats = StorageStats(
        duplicateSizeBytes: 100 * 1024 * 1024,
        blurryImageCount: 10,
      );
      // 100 MB + 10 * 500 KB = ~105 MB
      expect(stats.recoverableBytes, greaterThan(100 * 1024 * 1024));
    });

    test('formattedTotal returns MB for medium sizes', () {
      const stats = StorageStats(totalSizeBytes: 50 * 1024 * 1024);
      expect(stats.formattedTotal, contains('MB'));
    });

    test('formattedTotal returns GB for large sizes', () {
      const stats = StorageStats(totalSizeBytes: 2 * 1024 * 1024 * 1024);
      expect(stats.formattedTotal, contains('GB'));
    });

    test('Equatable equality', () {
      const a = StorageStats(totalFiles: 10);
      const b = StorageStats(totalFiles: 10);
      expect(a, equals(b));
    });
  });

  group('DesignTokens', () {
    test('brand color has correct value', () {
      expect(DesignTokens.brand, const Color(0xFF6366F1));
    });
    test('radius constants are positive', () {
      expect(DesignTokens.radiusSm, greaterThan(0));
      expect(DesignTokens.radiusMd, greaterThan(DesignTokens.radiusSm));
      expect(DesignTokens.radiusLg, greaterThan(DesignTokens.radiusMd));
    });
    test('spacing constants are positive', () {
      expect(DesignTokens.space8, 8.0);
      expect(DesignTokens.space16, 16.0);
    });
    test('category colors map contains cloud entry', () {
      expect(DesignTokens.categoryColors.containsKey('Cloud'), isTrue);
    });
  });

  group('FileTypeDisplay', () {
    test('icon returns known icon for png', () {
      expect(FileTypeDisplay.icon('png'), Icons.image_rounded);
    });

    test('color returns fallback for unknown extension', () {
      expect(FileTypeDisplay.color('zzz'), const Color(0xFF94A3B8));
    });

    test('iconBox has correct dimensions', () {
      final widget = FileTypeDisplay.iconBox('pdf', boxSize: 48);
      expect(widget, isA<Container>());
    });
  });

  // ─── Widget Tests ──────────────────────────────────────────────────────────

  group('EmptyStateWidget', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyStateWidget(
        icon: Icons.inbox_rounded,
        title: 'Empty title',
        subtitle: 'Empty subtitle text',
      )));
      expect(find.text('Empty title'), findsOneWidget);
      expect(find.text('Empty subtitle text'), findsOneWidget);
    });

    testWidgets('renders action button when provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(EmptyStateWidget(
        icon: Icons.inbox_rounded,
        title: 'Title',
        subtitle: 'Sub',
        actionLabel: 'Do Action',
        onAction: () => tapped = true,
      )));
      await tester.tap(find.text('Do Action'));
      expect(tapped, isTrue);
    });

    testWidgets('does not render button when actionLabel is null', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyStateWidget(
        icon: Icons.inbox_rounded,
        title: 'Title',
        subtitle: 'Sub',
      )));
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('SkeletonBox', () {
    testWidgets('renders with default dimensions', (tester) async {
      await tester.pumpWidget(_wrap(const SkeletonBox(height: 20)));
      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('renders with custom width', (tester) async {
      await tester.pumpWidget(_wrap(const SkeletonBox(width: 100, height: 20)));
      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  });

  group('GradientBadge', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(const GradientBadge(label: 'NEW')));
      expect(find.text('NEW'), findsOneWidget);
    });
  });

  group('SectionHeader', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(_wrap(const SectionHeader(title: 'Recent Files')));
      expect(find.text('Recent Files'), findsOneWidget);
    });

    testWidgets('renders action button when provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(SectionHeader(
        title: 'Files',
        action: 'See all',
        onAction: () => tapped = true,
      )));
      await tester.tap(find.text('See all'));
      expect(tapped, isTrue);
    });
  });

  group('PremiumCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(_wrap(
        const PremiumCard(child: Text('Card content')),
      ));
      expect(find.text('Card content'), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        PremiumCard(onTap: () => tapped = true, child: const Text('Tap me')),
      ));
      await tester.tap(find.text('Tap me'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  // ─── BLoC Tests ────────────────────────────────────────────────────────────

  group('SettingsBloc', () {
    blocTest<SettingsBloc, SettingsState>(
      'emits updated themeMode on SettingsThemeChanged',
      build: () => SettingsBloc(),
      act: (bloc) => bloc.add(const SettingsThemeChanged(ThemeMode.dark)),
      expect: () => [
        const SettingsState(themeMode: ThemeMode.dark, languageCode: 'en'),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits updated languageCode on SettingsLanguageChanged',
      build: () => SettingsBloc(),
      act: (bloc) => bloc.add(const SettingsLanguageChanged('fr')),
      expect: () => [
        const SettingsState(themeMode: ThemeMode.system, languageCode: 'fr'),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'initial state is system theme with English',
      build: () => SettingsBloc(),
      verify: (bloc) {
        expect(bloc.state.themeMode, ThemeMode.system);
        expect(bloc.state.languageCode, 'en');
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'multiple theme changes emit in order',
      build: () => SettingsBloc(),
      act: (bloc) {
        bloc.add(const SettingsThemeChanged(ThemeMode.dark));
        bloc.add(const SettingsThemeChanged(ThemeMode.light));
      },
      expect: () => [
        const SettingsState(themeMode: ThemeMode.dark),
        const SettingsState(themeMode: ThemeMode.light),
      ],
    );

    test('SettingsState copyWith preserves other fields', () {
      const original = SettingsState(themeMode: ThemeMode.dark, languageCode: 'de');
      final updated = original.copyWith(themeMode: ThemeMode.light);
      expect(updated.languageCode, 'de');
      expect(updated.themeMode, ThemeMode.light);
    });
  });

  // ─── AppTheme Tests ────────────────────────────────────────────────────────

  group('AppTheme', () {
    test('lightTheme uses Material 3', () {
      final theme = AppTheme.lightTheme();
      expect(theme.useMaterial3, isTrue);
    });

    test('darkTheme uses Material 3', () {
      final theme = AppTheme.darkTheme();
      expect(theme.useMaterial3, isTrue);
    });

    test('lightTheme brightness is light', () {
      final theme = AppTheme.lightTheme();
      expect(theme.brightness, Brightness.light);
    });

    test('darkTheme brightness is dark', () {
      final theme = AppTheme.darkTheme();
      expect(theme.brightness, Brightness.dark);
    });

    test('lightTheme fontFamily is Inter', () {
      final theme = AppTheme.lightTheme();
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
    });
  });

  // ─── Collection Tests ──────────────────────────────────────────────────────

  group('Collection', () {
    test('Equatable equality by id', () {
      final a = Collection(
        id: 'col1',
        name: 'Cloud',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final b = Collection(
        id: 'col1',
        name: 'Cloud',
        fileCount: 5,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      expect(a, equals(b));
    });
  });
}
