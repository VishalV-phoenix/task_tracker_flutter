/// =============================================
/// CATEGORY_MODEL.DART
/// Data class for a Category
///
/// Equivalent to JavaScript:
/// { id, name, icon, color, type, order }
///
/// Handles conversion between:
/// - Dart object (used in UI and state)
/// - Map (used for SQLite read/write)
/// - JSON (used for export/import)
/// =============================================

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;     // Hex string like '#4F46E5'
  final String type;      // 'kanban' or 'notes'
  final int sortOrder;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon = '📁',
    this.color = '#4F46E5',
    this.type = 'kanban',
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create CategoryModel from SQLite row (Map)
  /// Called when reading from database
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '📁',
      color: map['color'] as String? ?? '#4F46E5',
      type: map['type'] as String? ?? 'kanban',
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to Map for SQLite insert/update
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON-compatible map for export
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON import
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel.fromMap(json);
  }

  /// Create a copy with some fields changed
  /// Used for updates without mutating original
  CategoryModel copyWith({
    String? name,
    String? icon,
    String? color,
    String? type,
    int? sortOrder,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'Category($id: $name, $type)';
}