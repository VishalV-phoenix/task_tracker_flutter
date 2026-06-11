/// =============================================
/// ROADMAP_MODEL.DART
/// Checkpoint model for long-term goal roadmap
/// =============================================

class CheckpointModel {
  final String id;
  final String title;
  final String? description;
  final String? notes;
  final int sortOrder;
  final bool completed;
  final DateTime createdAt;
  final List<String> linkedTaskIds; // Loaded from junction table

  CheckpointModel({
    required this.id,
    required this.title,
    this.description,
    this.notes,
    this.sortOrder = 0,
    this.completed = false,
    DateTime? createdAt,
    List<String>? linkedTaskIds,
  })  : createdAt = createdAt ?? DateTime.now(),
        linkedTaskIds = linkedTaskIds ?? [];

  factory CheckpointModel.fromMap(Map<String, dynamic> map) {
    return CheckpointModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      notes: map['notes'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      completed: (map['completed'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'notes': notes,
      'sort_order': sortOrder,
      'completed': completed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'notes': notes,
      'order': sortOrder,
      'completed': completed,
      'linkedTasks': linkedTaskIds,
    };
  }

  CheckpointModel copyWith({
    String? title,
    String? description,
    String? notes,
    int? sortOrder,
    bool? completed,
    List<String>? linkedTaskIds,
  }) {
    return CheckpointModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      linkedTaskIds: linkedTaskIds ?? this.linkedTaskIds,
    );
  }

  @override
  String toString() => 'Checkpoint($id: $title, done: $completed)';
}