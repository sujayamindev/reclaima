/// Notification preference settings for the current user.
/// Mirrors `UserNotificationPreferencesResponse` from the backend.
class NotificationPreferencesModel {
  final String id;
  final String userId;

  // Toggles
  final bool warrantyRemindersEnabled;
  final bool returnRemindersEnabled;
  final bool ocrNotificationsEnabled;

  // Lead times
  final int warrantyLeadDays;
  final int returnLeadDays;

  // Quiet hours (0-23 UTC hour values; null = no quiet hours)
  final int? quietHoursStart;
  final int? quietHoursEnd;

  const NotificationPreferencesModel({
    required this.id,
    required this.userId,
    this.warrantyRemindersEnabled = true,
    this.returnRemindersEnabled = true,
    this.ocrNotificationsEnabled = true,
    this.warrantyLeadDays = 30,
    this.returnLeadDays = 3,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      warrantyRemindersEnabled: json['warrantyRemindersEnabled'] as bool? ?? true,
      returnRemindersEnabled: json['returnRemindersEnabled'] as bool? ?? true,
      ocrNotificationsEnabled: json['ocrNotificationsEnabled'] as bool? ?? true,
      warrantyLeadDays: json['warrantyLeadDays'] as int? ?? 30,
      returnLeadDays: json['returnLeadDays'] as int? ?? 3,
      quietHoursStart: json['quietHoursStart'] as int?,
      quietHoursEnd: json['quietHoursEnd'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'warrantyRemindersEnabled': warrantyRemindersEnabled,
        'returnRemindersEnabled': returnRemindersEnabled,
        'ocrNotificationsEnabled': ocrNotificationsEnabled,
        'warrantyLeadDays': warrantyLeadDays,
        'returnLeadDays': returnLeadDays,
        if (quietHoursStart != null) 'quietHoursStart': quietHoursStart,
        if (quietHoursEnd != null) 'quietHoursEnd': quietHoursEnd,
      };

  /// Partial-update payload — only include non-null values that differ.
  Map<String, dynamic> toUpdateJson() => {
        'warrantyRemindersEnabled': warrantyRemindersEnabled,
        'returnRemindersEnabled': returnRemindersEnabled,
        'ocrNotificationsEnabled': ocrNotificationsEnabled,
        'warrantyLeadDays': warrantyLeadDays,
        'returnLeadDays': returnLeadDays,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
      };

  NotificationPreferencesModel copyWith({
    bool? warrantyRemindersEnabled,
    bool? returnRemindersEnabled,
    bool? ocrNotificationsEnabled,
    int? warrantyLeadDays,
    int? returnLeadDays,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool clearQuietHours = false,
  }) {
    return NotificationPreferencesModel(
      id: id,
      userId: userId,
      warrantyRemindersEnabled:
          warrantyRemindersEnabled ?? this.warrantyRemindersEnabled,
      returnRemindersEnabled:
          returnRemindersEnabled ?? this.returnRemindersEnabled,
      ocrNotificationsEnabled:
          ocrNotificationsEnabled ?? this.ocrNotificationsEnabled,
      warrantyLeadDays: warrantyLeadDays ?? this.warrantyLeadDays,
      returnLeadDays: returnLeadDays ?? this.returnLeadDays,
      quietHoursStart: clearQuietHours ? null : (quietHoursStart ?? this.quietHoursStart),
      quietHoursEnd: clearQuietHours ? null : (quietHoursEnd ?? this.quietHoursEnd),
    );
  }
}
