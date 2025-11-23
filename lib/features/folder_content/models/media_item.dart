// lib/features/folder_content/models/media_item.dart
enum MediaType { image, video, document }

class MediaItem {
  final String id;
  final String name;
  final MediaType type;
  final DateTime createdDate;
  final String filePath;
  final String folderId;
  final int fileSize;
  final Duration? duration;
  final String? thumbnailPath; // Add thumbnail path for videos

  MediaItem({
    required this.id,
    required this.name,
    required this.type,
    required this.createdDate,
    required this.filePath,
    required this.folderId,
    this.fileSize = 0,
    this.duration,
    this.thumbnailPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'createdDate': createdDate.millisecondsSinceEpoch,
      'filePath': filePath,
      'folderId': folderId,
      'fileSize': fileSize,
      'duration': duration?.inMilliseconds,
      'thumbnailPath': thumbnailPath,
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'],
      name: json['name'],
      type: MediaType.values[json['type']],
      createdDate: DateTime.fromMillisecondsSinceEpoch(json['createdDate']),
      filePath: json['filePath'],
      folderId: json['folderId'],
      fileSize: json['fileSize'] ?? 0,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'])
          : null,
      thumbnailPath: json['thumbnailPath'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
