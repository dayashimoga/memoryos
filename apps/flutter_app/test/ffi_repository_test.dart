import 'package:flutter_test/flutter_test.dart';
import 'package:memoryos/core/domain/entities.dart';
import 'package:memoryos/core/domain/ffi_repositories.dart';

void main() {
  group('FfiFileRepository.parseFileEntry', () {
    test('parses all fields including ocr_text, summary, and phash', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'path': '/home/user/doc.pdf',
        'filename': 'doc.pdf',
        'extension': 'pdf',
        'size_bytes': 1024000,
        'created_at': '2026-07-01T12:00:00Z',
        'modified_at': '2026-07-01T14:00:00Z',
        'tags': ['document', 'finance'],
        'summary': 'A financial report summary',
        'ocr_text': 'Extracted OCR text from the document',
        'phash': '12345678901234',
        'indexing_status': 'Completed',
        'is_favorite': true,
      };

      final entry = FfiFileRepository.parseFileEntry(json);

      expect(entry.id, '550e8400-e29b-41d4-a716-446655440000');
      expect(entry.path, '/home/user/doc.pdf');
      expect(entry.filename, 'doc.pdf');
      expect(entry.extension, 'pdf');
      expect(entry.sizeBytes, 1024000);
      expect(entry.tags, ['document', 'finance']);
      expect(entry.summary, 'A financial report summary');
      expect(entry.ocrText, 'Extracted OCR text from the document');
      expect(entry.phash, '12345678901234');
      expect(entry.indexingStatus, IndexingStatus.completed);
      expect(entry.isFavorite, true);
    });

    test('handles null optional fields gracefully', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'path': '/home/user/photo.jpg',
        'filename': 'photo.jpg',
        'extension': 'jpg',
        'size_bytes': 500000,
        'created_at': '2026-07-01T12:00:00Z',
        'modified_at': '2026-07-01T14:00:00Z',
        'tags': [],
        'summary': null,
        'ocr_text': null,
        'phash': null,
        'indexing_status': 'Pending',
        'is_favorite': false,
      };

      final entry = FfiFileRepository.parseFileEntry(json);

      expect(entry.summary, isNull);
      expect(entry.ocrText, isNull);
      expect(entry.phash, isNull);
      expect(entry.indexingStatus, IndexingStatus.pending);
      expect(entry.isFavorite, false);
    });

    test('handles integer is_favorite (SQLite returns 0/1)', () {
      final json = {
        'id': 'test-id',
        'path': '/test',
        'filename': 'test.txt',
        'extension': 'txt',
        'size_bytes': 100,
        'is_favorite': 1,
        'indexing_status': 'Completed',
      };

      final entry = FfiFileRepository.parseFileEntry(json);
      expect(entry.isFavorite, true);
    });

    test('handles quoted indexing_status from serde_json', () {
      final json = {
        'id': 'test-id',
        'path': '/test',
        'filename': 'test.txt',
        'extension': 'txt',
        'size_bytes': 100,
        'indexing_status': '"Completed"',
      };

      final entry = FfiFileRepository.parseFileEntry(json);
      expect(entry.indexingStatus, IndexingStatus.completed);
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{
        'id': '',
        'path': '',
      };

      final entry = FfiFileRepository.parseFileEntry(json);

      expect(entry.id, '');
      expect(entry.filename, '');
      expect(entry.sizeBytes, 0);
      expect(entry.tags, isEmpty);
      expect(entry.indexingStatus, IndexingStatus.pending);
      expect(entry.isFavorite, false);
    });

    test('correctly identifies file type from extension', () {
      final imageJson = {
        'id': 'id1',
        'path': '/photo.jpg',
        'filename': 'photo.jpg',
        'extension': 'jpg',
        'size_bytes': 1000,
      };

      final audioJson = {
        'id': 'id2',
        'path': '/song.mp3',
        'filename': 'song.mp3',
        'extension': 'mp3',
        'size_bytes': 5000,
      };

      expect(
          FfiFileRepository.parseFileEntry(imageJson).fileType, FileType.image);
      expect(
          FfiFileRepository.parseFileEntry(audioJson).fileType, FileType.audio);
    });
  });
}
