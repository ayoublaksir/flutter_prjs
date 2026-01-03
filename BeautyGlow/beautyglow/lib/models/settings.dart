import 'package:hive/hive.dart';

part 'settings.g.dart';

/// App settings model
@HiveType(typeId: 6)
class Settings extends HiveObject {
  @HiveField(0)
  bool routineReminders;

  @HiveField(1)
  bool achievementAlerts;

  @HiveField(2)
  String themeMode; // 'light', 'dark', 'system'

  Settings({
    this.routineReminders = true,
    this.achievementAlerts = true,
    this.themeMode = 'system',
  });

  /// Create default settings
  factory Settings.defaultSettings() {
    return Settings(
      routineReminders: true,
      achievementAlerts: true,
      themeMode: 'system',
    );
  }

  /// Update settings
  void updateSettings({
    bool? routineReminders,
    bool? achievementAlerts,
    String? themeMode,
  }) {
    if (routineReminders != null) this.routineReminders = routineReminders;
    if (achievementAlerts != null) this.achievementAlerts = achievementAlerts;
    if (themeMode != null) this.themeMode = themeMode;
    save();
  }
}
