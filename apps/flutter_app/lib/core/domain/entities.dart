/// Expanded entity model for v1.2.

import 'package:equatable/equatable.dart';

// ─── File Type ─────────────────────────────────────────────────────────────────

enum FileType {
  image,
  video,
  audio,
  document,
  spreadsheet,
  presentation,
  pdf,
  archive,
  code,
  markdown,
  text,
  font,
  database,
  unknown;

  static FileType fromExtension(String ext) {
    final e = ext.toLowerCase().replaceFirst('.', '');
    return switch (e) {
      'jpg' ||
      'jpeg' ||
      'png' ||
      'gif' ||
      'webp' ||
      'bmp' ||
      'tiff' ||
      'tif' ||
      'heic' ||
      'heif' ||
      'avif' ||
      'svg' =>
        FileType.image,
      'mp4' ||
      'mov' ||
      'avi' ||
      'mkv' ||
      'webm' ||
      'flv' ||
      'm4v' ||
      'wmv' ||
      '3gp' =>
        FileType.video,
      'mp3' ||
      'flac' ||
      'wav' ||
      'ogg' ||
      'aac' ||
      'm4a' ||
      'opus' ||
      'wma' =>
        FileType.audio,
      'doc' || 'docx' || 'odt' || 'rtf' || 'pages' => FileType.document,
      'xls' || 'xlsx' || 'ods' || 'numbers' || 'csv' => FileType.spreadsheet,
      'ppt' || 'pptx' || 'odp' || 'key' => FileType.presentation,
      'pdf' => FileType.pdf,
      'zip' ||
      'tar' ||
      'gz' ||
      'bz2' ||
      'rar' ||
      '7z' ||
      'xz' ||
      'zst' =>
        FileType.archive,
      'py' ||
      'js' ||
      'ts' ||
      'dart' ||
      'rs' ||
      'go' ||
      'java' ||
      'kt' ||
      'swift' ||
      'c' ||
      'cpp' ||
      'h' ||
      'cs' ||
      'rb' ||
      'php' ||
      'sh' ||
      'bash' ||
      'json' ||
      'yaml' ||
      'yml' ||
      'toml' ||
      'xml' ||
      'html' ||
      'css' ||
      'sql' ||
      'tf' =>
        FileType.code,
      'md' || 'mdx' || 'rst' => FileType.markdown,
      'txt' || 'log' || 'conf' || 'ini' || 'env' => FileType.text,
      'ttf' || 'otf' || 'woff' || 'woff2' => FileType.font,
      'db' || 'sqlite' || 'sqlite3' => FileType.database,
      _ => FileType.unknown,
    };
  }

  bool get isMedia =>
      this == FileType.image ||
      this == FileType.video ||
      this == FileType.audio;
  bool get isDocument =>
      this == FileType.document ||
      this == FileType.pdf ||
      this == FileType.spreadsheet ||
      this == FileType.presentation ||
      this == FileType.markdown ||
      this == FileType.text;
  bool get isCode => this == FileType.code;
}

// ─── IndexingStatus ────────────────────────────────────────────────────────────

enum IndexingStatus { pending, indexing, completed, failed }

// ─── Tag ──────────────────────────────────────────────────────────────────────

class Tag extends Equatable {
  final String id;
  final String name;
  final String? color;

  const Tag({required this.id, required this.name, this.color});

  @override
  List<Object?> get props => [id];
}

// ─── FileEntry ─────────────────────────────────────────────────────────────────

class FileEntry extends Equatable {
  final String id;
  final String path;
  final String filename;
  final String extension;
  final FileType fileType;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final List<String> tags;
  final String? summary;
  final IndexingStatus indexingStatus;
  final bool isFavorite;
  final String? ocrText;
  final String? phash;

  const FileEntry({
    required this.id,
    required this.path,
    required this.filename,
    required this.extension,
    required this.fileType,
    required this.sizeBytes,
    required this.createdAt,
    required this.modifiedAt,
    this.tags = const [],
    this.summary,
    this.indexingStatus = IndexingStatus.completed,
    this.isFavorite = false,
    this.ocrText,
    this.phash,
  });

  String get formattedSize {
    final b = sizeBytes;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1024 * 1024 * 1024)
      return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(modifiedAt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  FileEntry copyWith({
    String? id,
    String? path,
    String? filename,
    String? extension,
    FileType? fileType,
    int? sizeBytes,
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<String>? tags,
    String? summary,
    IndexingStatus? indexingStatus,
    bool? isFavorite,
    String? ocrText,
    String? phash,
  }) =>
      FileEntry(
        id: id ?? this.id,
        path: path ?? this.path,
        filename: filename ?? this.filename,
        extension: extension ?? this.extension,
        fileType: fileType ?? this.fileType,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        createdAt: createdAt ?? this.createdAt,
        modifiedAt: modifiedAt ?? this.modifiedAt,
        tags: tags ?? this.tags,
        summary: summary ?? this.summary,
        indexingStatus: indexingStatus ?? this.indexingStatus,
        isFavorite: isFavorite ?? this.isFavorite,
        ocrText: ocrText ?? this.ocrText,
        phash: phash ?? this.phash,
      );

  @override
  List<Object?> get props => [id];
}

// ─── Collection ────────────────────────────────────────────────────────────────

class Collection extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final String? colorHex;
  final int fileCount;
  final bool isSmart;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Collection({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    this.colorHex,
    this.fileCount = 0,
    this.isSmart = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Collection copyWith({
    String? id,
    String? name,
    String? description,
    int? fileCount,
    bool? isSmart,
  }) =>
      Collection(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        iconName: iconName,
        colorHex: colorHex,
        fileCount: fileCount ?? this.fileCount,
        isSmart: isSmart ?? this.isSmart,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  @override
  List<Object?> get props => [id];
}

// ─── StorageStats ──────────────────────────────────────────────────────────────

class StorageStats extends Equatable {
  final int totalFiles;
  final int totalSizeBytes;
  final int usedSizeBytes;
  final int duplicateSizeBytes;
  final int blurryImageCount;

  const StorageStats({
    this.totalFiles = 0,
    this.totalSizeBytes = 0,
    this.usedSizeBytes = 0,
    this.duplicateSizeBytes = 0,
    this.blurryImageCount = 0,
  });

  int get recoverableBytes =>
      duplicateSizeBytes + blurryImageCount * 512 * 1024;

  String get formattedTotal => _fmt(totalSizeBytes);
  String get formattedUsed => _fmt(usedSizeBytes);
  String get formattedRecoverable => _fmt(recoverableBytes);

  String _fmt(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1024 * 1024 * 1024)
      return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  List<Object?> get props => [totalFiles, totalSizeBytes, duplicateSizeBytes];
}
