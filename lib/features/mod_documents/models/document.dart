/// A document in the staff document library, as returned by
/// `GET /staff/modules/documents`.
///
/// Documents are polymorphic on the backend (attached to a Trip, Vehicle or
/// Driver), so [type] is the related-entity kind and [relatedName] is its
/// flattened label (plate / name / trip number).
class StaffDocument {
  final int id;
  final String title;
  final String? type; // 'trip' | 'vehicle' | 'driver'
  final int? relatedId;
  final String? relatedName;
  final String? fileName;
  final String? filePath;
  final String? fileUrl;
  final String? mimeType;
  final int? fileSize;
  final String? fileSizeHuman;
  final String? notes;
  final DateTime? uploadedAt;

  const StaffDocument({
    required this.id,
    required this.title,
    this.type,
    this.relatedId,
    this.relatedName,
    this.fileName,
    this.filePath,
    this.fileUrl,
    this.mimeType,
    this.fileSize,
    this.fileSizeHuman,
    this.notes,
    this.uploadedAt,
  });

  factory StaffDocument.fromJson(Map<String, dynamic> j) => StaffDocument(
        id: j['id'] as int,
        title: j['title'] as String? ?? 'Untitled',
        type: (j['type'] ?? j['related_type']) as String?,
        relatedId: j['related_id'] as int?,
        relatedName: j['related_name'] as String?,
        fileName: j['file_name'] as String?,
        filePath: j['file_path'] as String?,
        fileUrl: j['file_url'] as String?,
        mimeType: j['mime_type'] as String?,
        fileSize: j['file_size'] is num ? (j['file_size'] as num).toInt() : null,
        fileSizeHuman: j['file_size_human'] as String?,
        notes: j['notes'] as String?,
        uploadedAt: j['uploaded_at'] != null
            ? DateTime.tryParse(j['uploaded_at'].toString())
            : null,
      );

  /// Friendly label for the related-entity type.
  String get typeLabel {
    switch (type) {
      case 'trip':
        return 'Trip';
      case 'vehicle':
        return 'Vehicle';
      case 'driver':
        return 'Driver';
      default:
        return 'Document';
    }
  }

  /// File extension (upper-cased), derived from the file name when available.
  String? get extension {
    final name = fileName;
    if (name == null || !name.contains('.')) return null;
    return name.split('.').last.toUpperCase();
  }

  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;
}
