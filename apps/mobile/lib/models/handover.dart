import 'user.dart';

class HandoverSnapshot {
  const HandoverSnapshot({
    required this.shift,
    required this.handover,
    required this.currentUser,
    required this.acknowledged,
    required this.acknowledgedAt,
  });

  factory HandoverSnapshot.fromJson(Map<String, dynamic> json) {
    return HandoverSnapshot(
      shift: ShiftSummary.fromJson(json['shift'] as Map<String, dynamic>),
      handover: HandoverSummary.fromJson(
        json['handover'] as Map<String, dynamic>,
      ),
      currentUser: LoginUser.fromJson(
        json['currentUser'] as Map<String, dynamic>,
      ),
      acknowledged: json['acknowledged'] as bool,
      acknowledgedAt: json['acknowledgedAt'] == null
          ? null
          : DateTime.parse(json['acknowledgedAt'] as String),
    );
  }

  final ShiftSummary shift;
  final HandoverSummary handover;
  final LoginUser currentUser;
  final bool acknowledged;
  final DateTime? acknowledgedAt;
}

class ShiftSummary {
  const ShiftSummary({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.floorNumber,
    required this.unitLabel,
  });

  factory ShiftSummary.fromJson(Map<String, dynamic> json) {
    return ShiftSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      status: json['status'] as String,
      floorNumber: json['floorNumber'] as int? ?? 1,
      unitLabel: json['unitLabel'] as String? ?? 'Willow Floor',
    );
  }

  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final int floorNumber;
  final String unitLabel;
}

class HandoverSummary {
  const HandoverSummary({
    required this.id,
    required this.summary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HandoverSummary.fromJson(Map<String, dynamic> json) {
    return HandoverSummary(
      id: json['id'] as String,
      summary: json['summary'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String summary;
  final DateTime createdAt;
  final DateTime updatedAt;
}
