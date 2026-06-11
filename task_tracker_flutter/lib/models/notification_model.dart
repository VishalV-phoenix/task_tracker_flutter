/// =============================================
/// NOTIFICATION_MODEL.DART
/// In-app notification for due date alerts
/// =============================================

class NotificationModel {
  final String id;
  final String taskId;
  final String taskTitle;
  final String? categoryName;
  final String? categoryIcon;
  final String type;       // 'overdue', 'critical', 'warning', etc.
  final DateTime? dueDate;
  final String? message;
  final DateTime createdAt;
  final bool dismissed;

  NotificationModel({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    this.categoryName,
    this.categoryIcon,
    this.type = 'warning',
    this.dueDate,
    this.message,
    DateTime? createdAt,
    this.dismissed = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      taskTitle: map['task_title'] as String,
      categoryName: map['category_name'] as String?,
      categoryIcon: map['category_icon'] as String?,
      type: map['type'] as String? ?? 'warning',
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      message: map['message'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      dismissed: (map['dismissed'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'task_title': taskTitle,
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'type': type,
      'due_date': dueDate?.toIso8601String(),
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'dismissed': dismissed ? 1 : 0,
    };
  }

  NotificationModel copyWith({bool? dismissed, String? type, String? message}) {
    return NotificationModel(
      id: id,
      taskId: taskId,
      taskTitle: taskTitle,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      type: type ?? this.type,
      dueDate: dueDate,
      message: message ?? this.message,
      createdAt: createdAt,
      dismissed: dismissed ?? this.dismissed,
    );
  }

  @override
  String toString() => 'Notification($id: $taskTitle, $type)';
}