import 'package:flutter_test/flutter_test.dart';
import 'package:memoryos/core/domain/entities.dart';

void main() {
  group('FileType.fromExtension', () {
    test('classifies image formats correctly', () {
      for (final ext in ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'svg']) {
        expect(FileType.fromExtension(ext), FileType.image, reason: 'Expected $ext to be image');
      }
    });

    test('classifies video formats correctly', () {
      for (final ext in ['mp4', 'mov', 'avi', 'mkv', 'webm']) {
        expect(FileType.fromExtension(ext), FileType.video, reason: 'Expected $ext to be video');
      }
    });

    test('classifies audio formats correctly', () {
      for (final ext in ['mp3', 'flac', 'wav', 'ogg', 'aac', 'm4a']) {
        expect(FileType.fromExtension(ext), FileType.audio, reason: 'Expected $ext to be audio');
      }
    });

    test('classifies document formats correctly', () {
      for (final ext in ['doc', 'docx', 'odt', 'rtf']) {
        expect(FileType.fromExtension(ext), FileType.document, reason: 'Expected $ext to be document');
      }
    });

    test('classifies code formats correctly', () {
      for (final ext in ['py', 'js', 'ts', 'dart', 'rs', 'go', 'java', 'json', 'yaml', 'html', 'css', 'sql']) {
        expect(FileType.fromExtension(ext), FileType.code, reason: 'Expected $ext to be code');
      }
    });

    test('classifies archive formats correctly', () {
      for (final ext in ['zip', 'tar', 'gz', 'rar', '7z']) {
        expect(FileType.fromExtension(ext), FileType.archive, reason: 'Expected $ext to be archive');
      }
    });

    test('classifies markdown correctly', () {
      expect(FileType.fromExtension('md'), FileType.markdown);
      expect(FileType.fromExtension('mdx'), FileType.markdown);
    });

    test('classifies pdf correctly', () {
      expect(FileType.fromExtension('pdf'), FileType.pdf);
    });

    test('handles dot prefix', () {
      expect(FileType.fromExtension('.png'), FileType.image);
    });

    test('handles uppercase', () {
      expect(FileType.fromExtension('PNG'), FileType.image);
      expect(FileType.fromExtension('MP4'), FileType.video);
    });

    test('returns unknown for unrecognized', () {
      expect(FileType.fromExtension('xyz'), FileType.unknown);
      expect(FileType.fromExtension(''), FileType.unknown);
    });

    test('isMedia property', () {
      expect(FileType.image.isMedia, true);
      expect(FileType.video.isMedia, true);
      expect(FileType.audio.isMedia, true);
      expect(FileType.document.isMedia, false);
    });

    test('isDocument property', () {
      expect(FileType.document.isDocument, true);
      expect(FileType.pdf.isDocument, true);
      expect(FileType.markdown.isDocument, true);
      expect(FileType.text.isDocument, true);
      expect(FileType.image.isDocument, false);
    });
  });

  group('FileEntry', () {
    final now = DateTime.now();
    final entry = FileEntry(
      id: 'test-id-1',
      path: '/home/user/photo.jpg',
      filename: 'photo.jpg',
      extension: 'jpg',
      fileType: FileType.image,
      sizeBytes: 1536000,
      createdAt: now,
      modifiedAt: now,
      tags: ['nature', 'landscape'],
      summary: 'A beautiful landscape photo',
    );

    test('formattedSize displays MB correctly', () {
      expect(entry.formattedSize, '1.5 MB');
    });

    test('formattedSize displays bytes correctly', () {
      final small = entry.copyWith(sizeBytes: 512);
      expect(small.formattedSize, '512 B');
    });

    test('formattedSize displays KB correctly', () {
      final kb = entry.copyWith(sizeBytes: 2048);
      expect(kb.formattedSize, '2.0 KB');
    });

    test('formattedSize displays GB correctly', () {
      final gb = entry.copyWith(sizeBytes: 2147483648);
      expect(gb.formattedSize, '2.00 GB');
    });

    test('timeAgo shows just now', () {
      final recent = entry.copyWith(modifiedAt: DateTime.now());
      expect(recent.timeAgo, 'just now');
    });

    test('timeAgo shows minutes', () {
      final past = entry.copyWith(
          modifiedAt: DateTime.now().subtract(const Duration(minutes: 30)));
      expect(past.timeAgo, '30m ago');
    });

    test('timeAgo shows hours', () {
      final past = entry.copyWith(
          modifiedAt: DateTime.now().subtract(const Duration(hours: 5)));
      expect(past.timeAgo, '5h ago');
    });

    test('timeAgo shows days', () {
      final past = entry.copyWith(
          modifiedAt: DateTime.now().subtract(const Duration(days: 3)));
      expect(past.timeAgo, '3d ago');
    });

    test('copyWith preserves unmodified fields', () {
      final copy = entry.copyWith(filename: 'updated.jpg');
      expect(copy.filename, 'updated.jpg');
      expect(copy.id, entry.id);
      expect(copy.path, entry.path);
      expect(copy.tags, entry.tags);
    });

    test('equality is based on id', () {
      final copy = entry.copyWith(filename: 'different.jpg');
      expect(entry, equals(copy));
    });
  });

  group('StorageStats', () {
    test('formattedTotal for zero', () {
      const stats = StorageStats();
      expect(stats.formattedTotal, '0 B');
    });

    test('formattedTotal for large size', () {
      const stats = StorageStats(totalSizeBytes: 5368709120);
      expect(stats.formattedTotal, '5.00 GB');
    });

    test('recoverableBytes calculation', () {
      const stats = StorageStats(
          duplicateSizeBytes: 1000000, blurryImageCount: 10);
      expect(stats.recoverableBytes, 1000000 + 10 * 512 * 1024);
    });
  });

  group('Collection', () {
    test('copyWith updates fields', () {
      final now = DateTime.now();
      final col = Collection(
        id: 'col-1',
        name: 'Test Collection',
        createdAt: now,
        updatedAt: now,
      );
      final updated = col.copyWith(name: 'Renamed', fileCount: 5);
      expect(updated.name, 'Renamed');
      expect(updated.fileCount, 5);
      expect(updated.id, 'col-1');
    });

    test('equality is based on id', () {
      final now = DateTime.now();
      final a = Collection(id: 'x', name: 'A', createdAt: now, updatedAt: now);
      final b = Collection(id: 'x', name: 'B', createdAt: now, updatedAt: now);
      expect(a, equals(b));
    });
  });

  group('Tag', () {
    test('equality is based on id', () {
      const a = Tag(id: 't1', name: 'Alpha');
      const b = Tag(id: 't1', name: 'Beta');
      expect(a, equals(b));
    });
  });
}
