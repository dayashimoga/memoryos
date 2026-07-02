/// Stub implementation of RustFfi — used on web and when native library
/// cannot be loaded. All methods return safe no-op values.
class RustFfi {
  // Lifecycle
  static void initialize() {}
  static bool get isAvailable => false;
  static int init(String dataDir) => -1;
  static bool isInitialized() => false;
  static String getVersion() => '0.1.0-stub';

  // File queries
  static int countFiles() => 0;
  static String listFiles(int limit, int offset) => '[]';
  static String getFile(String id) => 'null';
  static String search(String query) => '[]';
  static String storageStats() => '{}';

  // Indexing & deletion
  static int indexFile(String path) => -1;
  static int batchDelete(List<String> ids) => 0;
  static int hashFile(String fileId) => -1;

  // Vault
  static int vaultAdd(String id) => -1;
  static int vaultRemove(String id) => -1;
  static String vaultList() => '[]';

  // Favorites
  static int toggleFavorite(String id) => -1;
  static String listFavorites() => '[]';

  // Tags
  static String tagList() => '[]';
  static int tagCreate(String name, String color) => -1;
  static int tagFile(String fileId, String tagId) => -1;

  // Collections
  static String collectionList() => '[]';
  static int collectionCreate(String name, String description) => -1;
  static int collectionAddFile(String collectionId, String fileId) => -1;

  // Toolbox — Document conversion
  static int convertDocument(String input, String output) => -1;

  // Toolbox — Image processing
  static int processImage(
          String input, String output, int width, int height, int quality) =>
      -1;

  // Toolbox — Audio
  static int normalizeWav(String input, String output) => -1;

  // Toolbox — Archive (no password params — handled at Rust layer)
  static String archiveList(String path) => '[]';
  static int archiveCreate(String path, List<String> files) => -1;
  static int archiveExtract(String path, String dest) => -1;

  // Toolbox — Encrypted backup
  static int backupPerform(
          String dataDir, String backupPath, String keyPhrase) =>
      -1;
  static int backupRestore(
          String backupPath, String dataDir, String keyPhrase) =>
      -1;

  // Storage analytics
  static String getLargeFiles(int minSizeMb) => '[]';
  static String getDuplicateGroups() => '[]';
  static String getSimilarGroups() => '[]';
  static String recentFiles(int limit) => '[]';

  // AI & categorization
  static String categorizeText(String text) => '["Unknown"]';

  // New FFI endpoints
  static String searchFts(String query) => '[]';
  static int indexDirectory(String dirPath) => -1;
  static String getTimeline(String from, String to, int limit) => '[]';
  static String listCategories() => '[]';
  static String getFilesByCategory(String category) => '[]';
  static int saveSearchQuery(String query, int resultCount) => -1;
  static String getSearchHistory(int limit) => '[]';
  static String getProcessingStatus() => '{}';
  static int generateThumbnail(String inputPath, String outputPath, int size) =>
      -1;
  static String getFilesByType(String fileType, int limit) => '[]';
  static String getFilesInCollection(String collectionId) => '[]';
}
