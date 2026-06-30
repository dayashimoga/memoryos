class RustFfi {
  static void initialize() {}
  static bool get isAvailable => false;
  static int init(String dataDir) => -1;
  static bool isInitialized() => false;
  static String getVersion() => '0.1.0-stub';
  static int countFiles() => 0;
  static String listFiles(int limit, int offset) => '[]';
  static String getFile(String id) => 'null';
  static String search(String query) => '[]';
  static String storageStats() => '{}';
  static int indexFile(String path) => -1;
  static int batchDelete(List<String> ids) => 0;
  static int vaultAdd(String id) => -1;
  static int vaultRemove(String id) => -1;
  static String vaultList() => '[]';
  static int convertDocument(String input, String output) => -1;
  static int processImage(
          String input, String output, int width, int height, int quality) =>
      -1;
  static int normalizeWav(String input, String output) => -1;
  static String archiveList(String path, String password) => '[]';
  static int archiveCreate(String path, List<String> files, String password) =>
      -1;
  static int archiveExtract(String path, String dest, String password) => -1;
  static int backupPerform(String path, String password) => -1;
  static int backupRestore(String path, String password) => -1;
  static String tagList() => '[]';
  static int tagCreate(String name, String color) => -1;
  static int tagFile(String fileId, String tagId) => -1;
  static String collectionList() => '[]';
  static int collectionCreate(String name, String description) => -1;
  static int collectionAddFile(String collectionId, String fileId) => -1;
  static String getLargeFiles(int minSizeMb) => '[]';
  static int hashFile(String fileId) => -1;
  static String getDuplicateGroups() => '[]';
  static String getSimilarGroups() => '[]';
  static String recentFiles(int limit) => '[]';
}
