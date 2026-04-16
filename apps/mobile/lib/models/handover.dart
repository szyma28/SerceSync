import 'user.dart';
import 'shared_models.dart';

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
          : parseApiDateTime(json['acknowledgedAt'] as String),
    );
  }

  final ShiftSummary shift;
  final HandoverSummary handover;
  final LoginUser currentUser;
  final bool acknowledged;
  final DateTime? acknowledgedAt;
}

class ShiftSummary extends ShiftPeriod {
  const ShiftSummary({
    required super.id,
    required super.name,
    required super.startsAt,
    required super.endsAt,
    required super.status,
    required super.floorNumber,
    required super.unitLabel,
  });

  factory ShiftSummary.fromJson(Map<String, dynamic> json) {
    return ShiftSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      startsAt: parseApiDateTime(json['startsAt'] as String),
      endsAt: parseApiDateTime(json['endsAt'] as String),
      status: ShiftStatusX.fromApiValue(json['status'] as String),
      floorNumber: json['floorNumber'] as int? ?? 1,
      unitLabel: json['unitLabel'] as String? ?? 'Willow Floor',
    );
  }
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
      createdAt: parseApiDateTime(json['createdAt'] as String),
      updatedAt: parseApiDateTime(json['updatedAt'] as String),
    );
  }

  final String id;
  final String summary;
  final DateTime createdAt;
  final DateTime updatedAt;
}
