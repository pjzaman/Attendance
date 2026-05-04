/// Lightweight metadata record for an employee document. v1 only
/// tracks title + filename + notes — actual file upload is deferred
/// (the Documents tab is metadata-only for now per the doc's "Phase 2
/// non-negotiable" cut).
class EmployeeDocument {
  EmployeeDocument({
    required this.id,
    required this.userId,
    required this.title,
    required this.filename,
    required this.uploadedAt,
    this.notes,
  });

  final String id;
  final String userId;
  final String title;
  final String filename;
  final DateTime uploadedAt;
  final String? notes;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'user_id': userId,
        'title': title,
        'filename': filename,
        'uploaded_at': uploadedAt.toUtc().toIso8601String(),
        'notes': notes,
      };

  factory EmployeeDocument.fromMap(Map<String, Object?> m) => EmployeeDocument(
        id: m['id']! as String,
        userId: m['user_id']! as String,
        title: m['title']! as String,
        filename: m['filename']! as String,
        uploadedAt: DateTime.parse(m['uploaded_at']! as String).toLocal(),
        notes: m['notes'] as String?,
      );
}
