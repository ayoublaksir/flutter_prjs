import 'package:hive/hive.dart';

part 'notification_settings.g.dart';

@HiveType(typeId: 7)
class NotificationSettings extends HiveObject {
  @HiveField(0)
  bool enabled;

  @HiveField(1)
  int hour;

  @HiveField(2)
  int minute;

  NotificationSettings({
    this.enabled = true,
    this.hour = 20,
    this.minute = 0,
  });
}
