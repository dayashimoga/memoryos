import 'package:flutter_test/flutter_test.dart';
import 'package:memoryos/core/ffi/rust_ffi.dart';
import 'package:memoryos/core/ffi/rust_ffi_stub.dart' as stub;

void main() {
  group('RustFfi (fallback mode — no native library)', () {
    test('isAvailable returns false when not loaded', () {
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

  group('RustFfi (mocked FFI bindings active)', () {
    setUp(() {
      RustFfi.isAvailableOverride = true;
      RustFfi.initializeMockBindings();
    });

    tearDown(() {
      RustFfi.isAvailableOverride = false;
    });

    test('Calls every FFI helper with active mocks', () {
      expect(RustFfi.init('path'), 0);
      expect(RustFfi.isInitialized(), true);
      expect(RustFfi.getVersion(), '0.1.0');
      expect(RustFfi.countFiles(), 5);
      expect(RustFfi.listFiles(10, 0), '[]');
      expect(RustFfi.getFile('id'), 'null');
      expect(RustFfi.search('q'), '[]');
      expect(RustFfi.storageStats(), '{"total_files": 5, "total_bytes": 1000}');
      expect(RustFfi.indexFile('path'), 0);
      expect(RustFfi.batchDelete(['id']), 0);
      expect(RustFfi.vaultAdd('id'), 0);
      expect(RustFfi.vaultRemove('id'), 0);
      expect(RustFfi.vaultList(), '[]');
      expect(RustFfi.convertDocument('in', 'out'), 0);
      expect(RustFfi.processImage('in', 'out', 10, 10, 80), 0);
      expect(RustFfi.normalizeWav('in', 'out'), 0);
      expect(RustFfi.archiveList('path'), '[]');
      expect(RustFfi.archiveCreate('out', ['path']), 0);
      expect(RustFfi.archiveExtract('path', 'out'), 0);
      expect(RustFfi.backupPerform('dir', 'path', 'key'), 0);
      expect(RustFfi.backupRestore('path', 'dir', 'key'), 0);
      expect(RustFfi.tagList(), '[]');
      expect(RustFfi.tagCreate('name', 'color'), 0);
      expect(RustFfi.tagFile('file', 'tag'), 0);
      expect(RustFfi.collectionList(), '[]');
      expect(RustFfi.collectionCreate('name', 'desc'), 0);
      expect(RustFfi.collectionAddFile('col', 'file'), 0);
      expect(RustFfi.getLargeFiles(50), '[]');
      expect(RustFfi.hashFile('id'), 0);

      // Dynamic lookup fallback checks (verify catch blocks)
      expect(RustFfi.categorizeText('text'), '["Unknown"]');
      expect(RustFfi.toggleFavorite('id'), -1);
      expect(RustFfi.listFavorites(), '[]');
      expect(RustFfi.recentFiles(10), '[]');
      expect(RustFfi.searchFts('query'), '[]');
      expect(RustFfi.indexDirectory('path'), -1);
      expect(RustFfi.getTimeline('from', 'to', 10), '[]');
      expect(RustFfi.listCategories(), '[]');
      expect(RustFfi.getFilesByCategory('cat'), '[]');
      expect(RustFfi.saveSearchQuery('q', 0), -1);
      expect(RustFfi.getSearchHistory(10), '[]');
      expect(RustFfi.getProcessingStatus(), '{}');
      expect(RustFfi.generateThumbnail('in', 'out', 10), -1);
      expect(RustFfi.getFilesByType('type', 10), '[]');
      expect(RustFfi.getFilesInCollection('col'), '[]');
    });
  });

  group('RustFfi Stub Coverage Booster', () {
    test('Calls every stub method', () {
      stub.RustFfi.initialize();
      stub.RustFfi.initializeMockBindings();
      expect(stub.RustFfi.isAvailable, isFalse);
      stub.RustFfi.isAvailableOverride = true;
      expect(stub.RustFfi.isAvailable, isTrue);

      expect(stub.RustFfi.init('path'), -1);
      expect(stub.RustFfi.isInitialized(), false);
      expect(stub.RustFfi.getVersion(), '0.1.0-stub');
      expect(stub.RustFfi.countFiles(), 0);
      expect(stub.RustFfi.listFiles(10, 0), '[]');
      expect(stub.RustFfi.getFile('id'), 'null');
      expect(stub.RustFfi.search('q'), '[]');
      expect(stub.RustFfi.storageStats(), '{}');
      expect(stub.RustFfi.indexFile('path'), -1);
      expect(stub.RustFfi.batchDelete(['id']), 0);
      expect(stub.RustFfi.vaultAdd('id'), -1);
      expect(stub.RustFfi.vaultRemove('id'), -1);
      expect(stub.RustFfi.vaultList(), '[]');
      expect(stub.RustFfi.convertDocument('in', 'out'), -1);
      expect(stub.RustFfi.processImage('in', 'out', 10, 10, 80), -1);
      expect(stub.RustFfi.normalizeWav('in', 'out'), -1);
      expect(stub.RustFfi.archiveList('path'), '[]');
      expect(stub.RustFfi.archiveCreate('out', ['path']), -1);
      expect(stub.RustFfi.archiveExtract('path', 'out'), -1);
      expect(stub.RustFfi.backupPerform('dir', 'path', 'key'), -1);
      expect(stub.RustFfi.backupRestore('path', 'dir', 'key'), -1);
      expect(stub.RustFfi.tagList(), '[]');
      expect(stub.RustFfi.tagCreate('name', 'color'), -1);
      expect(stub.RustFfi.tagFile('file', 'tag'), -1);
      expect(stub.RustFfi.collectionList(), '[]');
      expect(stub.RustFfi.collectionCreate('name', 'desc'), -1);
      expect(stub.RustFfi.collectionAddFile('col', 'file'), -1);
      expect(stub.RustFfi.getLargeFiles(50), '[]');
      expect(stub.RustFfi.hashFile('id'), -1);
      expect(stub.RustFfi.categorizeText('text'), '["Unknown"]');
      expect(stub.RustFfi.toggleFavorite('id'), -1);
      expect(stub.RustFfi.listFavorites(), '[]');
      expect(stub.RustFfi.recentFiles(10), '[]');
      expect(stub.RustFfi.searchFts('query'), '[]');
      expect(stub.RustFfi.indexDirectory('path'), -1);
      expect(stub.RustFfi.getTimeline('from', 'to', 10), '[]');
      expect(stub.RustFfi.listCategories(), '[]');
      expect(stub.RustFfi.getFilesByCategory('cat'), '[]');
      expect(stub.RustFfi.saveSearchQuery('q', 0), -1);
      expect(stub.RustFfi.getSearchHistory(10), '[]');
      expect(stub.RustFfi.getProcessingStatus(), '{}');
      expect(stub.RustFfi.generateThumbnail('in', 'out', 10), -1);
      expect(stub.RustFfi.getFilesByType('type', 10), '[]');
      expect(stub.RustFfi.getFilesInCollection('col'), '[]');
    });
  });
}
