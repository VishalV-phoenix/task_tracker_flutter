/// =============================================
/// SETTINGS_MODEL.DART
/// User preferences and app configuration
/// Single-row table in database
/// =============================================

class SettingsModel {
  final String theme;
  final String finalGoal;
  final double defaultNotifyBefore;  // hours
  final int autoArchiveDays;
  final bool notificationsEnabled;

  SettingsModel({
    this.theme = 'light',
    this.finalGoal = 'Bioinformatics',
    this.defaultNotifyBefore = 3.0,
    this.autoArchiveDays = 7,
    this.notificationsEnabled = true,
  });

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      theme: map['theme'] as String? ?? 'light',
      finalGoal: map['final_goal'] as String? ?? 'Bioinformatics',
      defaultNotifyBefore:
          (map['default_notify_before'] as num?)?.toDouble() ?? 3.0,
      autoArchiveDays: map['auto_archive_days'] as int? ?? 7,
      notificationsEnabled:
          (map['notifications_enabled'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1, // Always row 1
      'theme': theme,
      'final_goal': finalGoal,
      'default_notify_before': defaultNotifyBefore,
      'auto_archive_days': autoArchiveDays,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
    };
  }

  SettingsModel copyWith({
    String? theme,
    String? finalGoal,
    double? defaultNotifyBefore,
    int? autoArchiveDays,
    bool? notificationsEnabled,
  }) {
    return SettingsModel(
      theme: theme ?? this.theme,
      finalGoal: finalGoal ?? this.finalGoal,
      defaultNotifyBefore: defaultNotifyBefore ?? this.defaultNotifyBefore,
      autoArchiveDays: autoArchiveDays ?? this.autoArchiveDays,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  String toString() => 'Settings(theme: $theme, goal: $finalGoal)';
}