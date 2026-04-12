part of '../../manager_app.dart';

class ManagerUser {
  const ManagerUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  factory ManagerUser.fromJson(Map<String, dynamic> json) {
    return ManagerUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
    );
  }

  final String id;
  final String email;
  final String displayName;
  final String role;
}

class ManagerSession {
  const ManagerSession({required this.accessToken, required this.user});

  factory ManagerSession.fromJson(Map<String, dynamic> json) {
    return ManagerSession(
      accessToken: json['accessToken'] as String,
      user: ManagerUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final ManagerUser user;
}

class ManagerDashboardSnapshot {
  const ManagerDashboardSnapshot({
    required this.activeShift,
    required this.metrics,
    required this.exceptionFeed,
    required this.complianceSeries,
  });

  factory ManagerDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    return ManagerDashboardSnapshot(
      activeShift: ManagerShiftSummary.fromJson(
        json['activeShift'] as Map<String, dynamic>,
      ),
      metrics: ManagerDashboardMetrics.fromJson(
        json['metrics'] as Map<String, dynamic>,
      ),
      exceptionFeed: (json['exceptionFeed'] as List<dynamic>? ?? const [])
          .map(
            (entry) => ManagerExceptionFeedItem.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(),
      complianceSeries: (json['complianceSeries'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                ManagerCompliancePoint.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final ManagerShiftSummary activeShift;
  final ManagerDashboardMetrics metrics;
  final List<ManagerExceptionFeedItem> exceptionFeed;
  final List<ManagerCompliancePoint> complianceSeries;
}

class ManagerShiftSummary {
  const ManagerShiftSummary({
    required this.id,
    required this.name,
    required this.unitLabel,
    required this.floorNumber,
    required this.startsAt,
    required this.endsAt,
  });

  factory ManagerShiftSummary.fromJson(Map<String, dynamic> json) {
    return ManagerShiftSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      unitLabel: json['unitLabel'] as String,
      floorNumber: json['floorNumber'] as int,
      startsAt: DateTime.parse(json['startsAt'] as String).toLocal(),
      endsAt: DateTime.parse(json['endsAt'] as String).toLocal(),
    );
  }

  final String id;
  final String name;
  final String unitLabel;
  final int floorNumber;
  final DateTime startsAt;
  final DateTime endsAt;
}

class ManagerDashboardMetrics {
  const ManagerDashboardMetrics({
    required this.overdueTasks,
    required this.escalatedItems,
    required this.unreadHandovers,
    required this.shiftCompletionPercent,
  });

  factory ManagerDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return ManagerDashboardMetrics(
      overdueTasks: json['overdueTasks'] as int? ?? 0,
      escalatedItems: json['escalatedItems'] as int? ?? 0,
      unreadHandovers: json['unreadHandovers'] as int? ?? 0,
      shiftCompletionPercent: json['shiftCompletionPercent'] as int? ?? 0,
    );
  }

  final int overdueTasks;
  final int escalatedItems;
  final int unreadHandovers;
  final int shiftCompletionPercent;
}

class ManagerExceptionFeedItem {
  const ManagerExceptionFeedItem({
    required this.id,
    required this.title,
    required this.residentName,
    required this.roomLabel,
    required this.description,
    required this.badge,
    required this.badgeTone,
    required this.dueAt,
  });

  factory ManagerExceptionFeedItem.fromJson(Map<String, dynamic> json) {
    return ManagerExceptionFeedItem(
      id: json['id'] as String,
      title: json['title'] as String,
      residentName: json['residentName'] as String,
      roomLabel: json['roomLabel'] as String,
      description: json['description'] as String,
      badge: json['badge'] as String,
      badgeTone: json['badgeTone'] as String,
      dueAt: json['dueAt'] == null
          ? null
          : DateTime.parse(json['dueAt'] as String).toLocal(),
    );
  }

  final String id;
  final String title;
  final String residentName;
  final String roomLabel;
  final String description;
  final String badge;
  final String badgeTone;
  final DateTime? dueAt;
}

class ManagerCompliancePoint {
  const ManagerCompliancePoint({required this.timestamp, required this.value});

  factory ManagerCompliancePoint.fromJson(Map<String, dynamic> json) {
    return ManagerCompliancePoint(
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
      value: json['value'] as int? ?? 0,
    );
  }

  final DateTime timestamp;
  final int value;
}

class ManagerResidentRecord {
  const ManagerResidentRecord({
    required this.id,
    required this.fullName,
    required this.roomNumber,
    required this.roomLabel,
    required this.floorNumber,
    required this.unitLabel,
    required this.recognitionImageKey,
    required this.careSummary,
    required this.isActive,
  });

  factory ManagerResidentRecord.fromJson(Map<String, dynamic> json) {
    return ManagerResidentRecord(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      roomNumber: json['roomNumber'] as int,
      roomLabel: json['roomLabel'] as String,
      floorNumber: json['floorNumber'] as int,
      unitLabel: json['unitLabel'] as String,
      recognitionImageKey: json['recognitionImageKey'] as String,
      careSummary: json['careSummary'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  final String id;
  final String fullName;
  final int roomNumber;
  final String roomLabel;
  final int floorNumber;
  final String unitLabel;
  final String recognitionImageKey;
  final String careSummary;
  final bool isActive;
}

class ManagerResidentDraft {
  const ManagerResidentDraft({
    required this.fullName,
    required this.roomNumber,
    required this.floorNumber,
    required this.unitLabel,
    required this.recognitionImageKey,
    required this.careSummary,
    required this.isActive,
  });

  final String fullName;
  final int roomNumber;
  final int floorNumber;
  final String unitLabel;
  final String recognitionImageKey;
  final String careSummary;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'roomNumber': roomNumber,
      'floorNumber': floorNumber,
      'unitLabel': unitLabel,
      'recognitionImageKey': recognitionImageKey,
      'careSummary': careSummary,
      'isActive': isActive,
    };
  }
}
