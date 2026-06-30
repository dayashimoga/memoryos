import 'package:flutter_test/flutter_test.dart';
import 'package:memoryos/core/ffi/rust_ffi.dart';

void main() {
  group('RustFfi (fallback mode — no native library)', () {
    test('isAvailable returns false when not loaded', () {
      // RustFfi.initialize() is NOT called → simulates no native lib
      expect(RustFfi.isAvailable, false);
    });

    test('init returns -1 when unavailable', () {
      expect(RustFfi.init('/tmp/test'), -1);
    });

    test('isInitialized returns false when unavailable', () {
      expect(RustFfi.isInitialized(), false);
    });

    test('getVersion returns stub version', () {
      expect(RustFfi.getVersion(), '0.1.0-stub');
    });

    test('countFiles returns 0 when unavailable', () {
      expect(RustFfi.countFiles(), 0);
    });

    test('listFiles returns empty JSON array', () {
      expect(RustFfi.listFiles(10, 0), '[]');
    });

    test('getFile returns null string', () {
      expect(RustFfi.getFile('some-id'), 'null');
    });

    test('search returns empty array', () {
      expect(RustFfi.search('test query'), '[]');
    });

    test('storageStats returns empty object', () {
      expect(RustFfi.storageStats(), '{}');
    });

    test('indexFile returns -1', () {
      expect(RustFfi.indexFile('/some/path'), -1);
    });

    test('batchDelete returns 0', () {
      expect(RustFfi.batchDelete(['id1', 'id2']), 0);
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

    test('convertDocument returns -1', () {
      expect(RustFfi.convertDocument('in.md', 'out.html'), -1);
    });

    test('processImage returns -1', () {
      expect(RustFfi.processImage('in.jpg', 'out.jpg', 100, 100, 80), -1);
    });

    test('normalizeWav returns -1', () {
      expect(RustFfi.normalizeWav('in.wav', 'out.wav'), -1);
    });

    test('archiveList returns empty array', () {
      expect(RustFfi.archiveList('test.zip'), '[]');
    });

    test('archiveCreate returns -1', () {
      expect(RustFfi.archiveCreate('out.zip', ['f1', 'f2']), -1);
    });

    test('archiveExtract returns -1', () {
      expect(RustFfi.archiveExtract('test.zip', '/output'), -1);
    });

    test('backupPerform returns -1', () {
      expect(RustFfi.backupPerform('/data', '/backup.enc', 'pass'), -1);
    });

    test('backupRestore returns -1', () {
      expect(RustFfi.backupRestore('/backup.enc', '/data', 'pass'), -1);
    });

    test('tagList returns empty array', () {
      expect(RustFfi.tagList(), '[]');
    });

    test('tagCreate returns -1', () {
      expect(RustFfi.tagCreate('test', '#ff0000'), -1);
    });

    test('tagFile returns -1', () {
      expect(RustFfi.tagFile('file-id', 'tag-id'), -1);
    });

    test('collectionList returns empty array', () {
      expect(RustFfi.collectionList(), '[]');
    });

    test('collectionCreate returns -1', () {
      expect(RustFfi.collectionCreate('name', 'desc'), -1);
    });

    test('collectionAddFile returns -1', () {
      expect(RustFfi.collectionAddFile('col-id', 'file-id'), -1);
    });

    test('getLargeFiles returns empty array', () {
      expect(RustFfi.getLargeFiles(50), '[]');
    });

    test('hashFile returns -1', () {
      expect(RustFfi.hashFile('file-id'), -1);
    });

    // v1.2 additions
    test('categorizeText returns Unknown when unavailable', () {
      expect(RustFfi.categorizeText('some text'), '["Unknown"]');
    });

    test('toggleFavorite returns -1 when unavailable', () {
      expect(RustFfi.toggleFavorite('file-id'), -1);
    });

    test('listFavorites returns empty array when unavailable', () {
      expect(RustFfi.listFavorites(), '[]');
    });

    test('recentFiles returns empty array when unavailable', () {
      expect(RustFfi.recentFiles(10), '[]');
    });
  });
}
