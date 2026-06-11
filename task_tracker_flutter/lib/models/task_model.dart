/// =============================================
/// TASK_MODEL.DART
/// Data classes for Task, Subtask, and TaskLink
///
/// This is the most complex model because a Task
/// contains:
/// - Basic fields (title, status, due date)
/// - List of Subtasks (separate table)
/// - List of TaskLinks/URLs (separate table)
/// - List of linked task IDs (junction table)
///
/// The DAO handles loading all related data
/// and assembling it into this model
/// =============================================

// ── Subtask Model ────────────────────────────
// A single checklist item inside a task
class SubtaskModel {
  final String id;
  final String taskId;
  final String title;
  final bool completed;
  final String? note;
  final String? timestamp;
  final int sortOrder;

  SubtaskModel({
    required this.id,
    required this.taskId,
    required this.title,
    this.completed = false,
    this.note,
    this.timestamp,
    this.sortOrder = 0,
  });

  factory SubtaskModel.fromMap(Map<String, dynamic> map) {
    return SubtaskModel(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      title: map['title'] as String,
      completed: (map['completed'] as int? ?? 0) == 1,
      note: map['note'] as String?,
      timestamp: map['timestamp'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'completed': completed ? 1 : 0,
      'note': note,
      'timestamp': timestamp,
      'sort_order': sortOrder,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'note': note ?? '',
      'timestamp': timestamp ?? '',
    };
  }

  SubtaskModel copyWith({String? title, bool? completed, String? note}) {
    return SubtaskModel(
      id: id,
      taskId: taskId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      note: note ?? this.note,
      timestamp: timestamp,
      sortOrder: sortOrder,
    );
  }
}

// ── Task Link Model (URLs) ───────────────────
// External links attached to a task
// e.g., YouTube video, GitHub repo
class TaskLinkModel {
  final String id;
  final String taskId;
  final String label;
  final String url;
  final String? linkType;  // 'video', 'github', etc.
  final DateTime addedAt;
  final int sortOrder;

  TaskLinkModel({
    required this.id,
    required this.taskId,
    required this.label,
    required this.url,
    this.linkType,
    DateTime? addedAt,
    this.sortOrder = 0,
  }) : addedAt = addedAt ?? DateTime.now();

  factory TaskLinkModel.fromMap(Map<String, dynamic> map) {
    return TaskLinkModel(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      label: map['label'] as String,
      url: map['url'] as String,
      linkType: map['link_type'] as String?,
      addedAt: DateTime.parse(map['added_at'] as String),
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'label': label,
      'url': url,
      'link_type': linkType,
      'added_at': addedAt.toIso8601String(),
      'sort_order': sortOrder,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'url': url,
      'type': linkType ?? 'link',
      'addedAt': addedAt.toIso8601String(),
    };
  }
}

// ── Main Task Model ──────────────────────────
// Complete task with all related data loaded
class TaskModel {
  final String id;
  final String categoryId;
  final String title;
  final String? description;
  final String status;          // 'todo', 'inProgress', 'completed'
  final String? estimatedTime;
  final DateTime? dueDate;
  final double notifyBefore;    // hours
  final bool notified;
  final DateTime? completedAt;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data (loaded from separate tables)
  final List<SubtaskModel> subtasks;
  final List<TaskLinkModel> links;
  final List<String> linkedTaskIds;

  TaskModel({
    required this.id,
    required this.categoryId,
    required this.title,
    this.description,
    this.status = 'todo',
    this.estimatedTime,
    this.dueDate,
    this.notifyBefore = 3.0,
    this.notified = false,
    this.completedAt,
    this.archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SubtaskModel>? subtasks,
    List<TaskLinkModel>? links,
    List<String>? linkedTaskIds,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        subtasks = subtasks ?? [],
        links = links ?? [],
        linkedTaskIds = linkedTaskIds ?? [];

  /// Create from SQLite row
  /// NOTE: subtasks, links, linkedTaskIds are loaded separately by DAO
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: map['status'] as String? ?? 'todo',
      estimatedTime: map['estimated_time'] as String?,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      notifyBefore: (map['notify_before'] as num?)?.toDouble() ?? 3.0,
      notified: (map['notified'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      archivedAt: map['archived_at'] != null
          ? DateTime.parse(map['archived_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert task fields to Map for SQLite
  /// Does NOT include subtasks/links (those are separate tables)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'status': status,
      'estimated_time': estimatedTime,
      'due_date': dueDate?.toIso8601String(),
      'notify_before': notifyBefore,
      'notified': notified ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'archived_at': archivedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to JSON for export (includes everything)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'status': status,
      'estimatedTime': estimatedTime,
      'dueDate': dueDate?.toIso8601String(),
      'notifyBefore': notifyBefore,
      'notified': notified,
      'completedAt': completedAt?.toIso8601String(),
      'archivedAt': archivedAt?.toIso8601String(),
      'linkedTaskIds': linkedTaskIds,
      'links': links.map((l) => l.toJson()).toList(),
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create copy with changes
  TaskModel copyWith({
    String? title,
    String? description,
    String? status,
    String? estimatedTime,
    DateTime? dueDate,
    double? notifyBefore,
    bool? notified,
    DateTime? completedAt,
    DateTime? archivedAt,
    List<SubtaskModel>? subtasks,
    List<TaskLinkModel>? links,
    List<String>? linkedTaskIds,
    bool clearDueDate = false,
    bool clearCompletedAt = false,
    bool clearArchivedAt = false,
  }) {
    return TaskModel(
      id: id,
      categoryId: categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      notifyBefore: notifyBefore ?? this.notifyBefore,
      notified: notified ?? this.notified,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      subtasks: subtasks ?? this.subtasks,
      links: links ?? this.links,
      linkedTaskIds: linkedTaskIds ?? this.linkedTaskIds,
    );
  }

  /// Check if task is archived
  bool get isArchived => archivedAt != null;

  /// Count completed subtasks
  int get completedSubtasks => subtasks.where((s) => s.completed).length;

  /// Get own progress percentage
  int get ownProgress {
    if (subtasks.isEmpty) return status == 'completed' ? 100 : 0;
    return ((completedSubtasks / subtasks.length) * 100).round();
  }

  @override
  String toString() => 'Task($id: $title, $status)';
}