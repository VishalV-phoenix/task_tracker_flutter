/// =============================================
/// NOTE_MODEL.DART
/// Simple checkbox note for notes-type categories
/// =============================================

class NoteModel {
  final String id;
  final String categoryId;
  final String title;
  final String? content;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.categoryId,
    required this.title,
    this.content,
    this.completed = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      title: map['title'] as String,
      content: map['content'] as String?,
      completed: (map['completed'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'title': title,
      'content': content,
      'completed': completed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'title': title,
      'content': content,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  NoteModel copyWith({
    String? title,
    String? content,
    bool? completed,
  }) {
    return NoteModel(
      id: id,
      categoryId: categoryId,
      title: title ?? this.title,
      content: content ?? this.content,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() => 'Note($id: $title, done: $completed)';
}