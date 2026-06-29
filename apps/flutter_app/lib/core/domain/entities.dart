import 'package:equatable/equatable.dart';

/// Mirrors Rust [FileType] enum.
enum FileType {
  image,
  screenshot,
  document,
  spreadsheet,
  video,
  audio,
  archive,
  email,
  chat,
  markdown,
  html,
  text,
  unknown;

  static FileType fromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'heic':
      case 'tiff':
        return FileType.image;
      case 'pdf':
      case 'docx':
      case 'doc':
      case 'odt':
      case 'rtf':
        return FileType.document;
      case 'xlsx':
      case 'xls':
      case 'csv':
      case 'ods':
        return FileType.spreadsheet;
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
      case 'webm':
        return FileType.video;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'ogg':
      case 'm4a':
        return FileType.audio;
      case 'zip':
      case 'tar':
      case 'gz':
      case '7z':
      case 'rar':
        return FileType.archive;
      case 'eml':
      case 'mbox':
        return FileType.email;
      case 'md':
      case 'markdown':
        return FileType.markdown;
      case 'html':
      case 'htm':
        return FileType.html;
      case 'txt':
      case 'log':
        return FileType.text;
      default:
        return FileType.unknown;
    }
  }

  bool get isMedia => this == FileType.image || this == FileType.video || this == FileType.screenshot;
  bool get isDocument => this == FileType.document || this == FileType.spreadsheet || this == FileType.markdown || this == FileType.html;
  bool get isAudio => this == FileType.audio;
}

/// Mirrors Rust [IndexingStatus] enum.
enum IndexingStatus { pending, inProgress, completed, failed, skipped }

/// Core domain entity representing a tracked file.
class FileEntry extends Equatable {
  final String id;
  final String path;
  final String filename;
  final String extension;
  final FileType fileType;
  final int sizeBytes;
  final String? sha256Hash;
  final String? phash;
  final String? ocrText;
  final String? summary;
  final List<String> tags;
  final List<String> collectionIds;
  final bool isEncrypted;
  final IndexingStatus indexingStatus;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime? indexedAt;
  final bool isFavorite;
  final String? thumbnailPath;

  const FileEntry({
    required this.id,
    required this.path,
    required this.filename,
    required this.extension,
    required this.fileType,
    required this.sizeBytes,
    this.sha256Hash,
    this.phash,
    this.ocrText,
    this.summary,
    this.tags = const [],
    this.collectionIds = const [],
    this.isEncrypted = false,
    this.indexingStatus = IndexingStatus.pending,
    required this.createdAt,
    required this.modifiedAt,
    this.indexedAt,
    this.isFavorite = false,
    this.thumbnailPath,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(modifiedAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  FileEntry copyWith({
    String? summary,
    List<String>? tags,
    IndexingStatus? indexingStatus,
    bool? isFavorite,
    String? thumbnailPath,
    String? ocrText,
  }) =>
      FileEntry(
        id: id,
        path: path,
        filename: filename,
        extension: extension,
        fileType: fileType,
        sizeBytes: sizeBytes,
        sha256Hash: sha256Hash,
        phash: phash,
        ocrText: ocrText ?? this.ocrText,
        summary: summary ?? this.summary,
        tags: tags ?? this.tags,
        collectionIds: collectionIds,
        isEncrypted: isEncrypted,
        indexingStatus: indexingStatus ?? this.indexingStatus,
        createdAt: createdAt,
        modifiedAt: modifiedAt,
        indexedAt: indexedAt,
        isFavorite: isFavorite ?? this.isFavorite,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      );

  @override
  List<Object?> get props => [id, path, indexingStatus, tags, isFavorite];
}

/// Domain entity for a user or AI-generated tag.
class Tag extends Equatable {
  final String id;
  final String name;
  final String? color;
  final DateTime createdAt;

  const Tag({required this.id, required this.name, this.color, required this.createdAt});

  @override
  List<Object?> get props => [id, name];
}

/// Domain entity for a collection of files.
class Collection extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final int fileCount;
  final String? coverImagePath;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Collection({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.fileCount = 0,
    this.coverImagePath,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, fileCount];
}

/// Storage statistics summary.
class StorageStats extends Equatable {
  final int totalFiles;
  final int totalSizeBytes;
  final int duplicateSizeBytes;
  final int blurryImageCount;
  final int emptyScreenshotCount;
  final int tagCount;
  final int collectionCount;

  const StorageStats({
    this.totalFiles = 0,
    this.totalSizeBytes = 0,
    this.duplicateSizeBytes = 0,
    this.blurryImageCount = 0,
    this.emptyScreenshotCount = 0,
    this.tagCount = 0,
    this.collectionCount = 0,
  });

  int get recoverableBytes => duplicateSizeBytes + (blurryImageCount * 500000);

  String get formattedTotal {
    if (totalSizeBytes < 1024 * 1024) return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    if (totalSizeBytes < 1024 * 1024 * 1024) {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedRecoverable {
    final bytes = recoverableBytes;
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  List<Object?> get props => [totalFiles, totalSizeBytes, tagCount, collectionCount];
}
