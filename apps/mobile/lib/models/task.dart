import 'shared_models.dart';

class ShiftTask extends TaskRecord {
  const ShiftTask({
    required super.id,
    required super.title,
    super.description,
    super.dueAt,
    required super.status,
    this.statusNote,
    super.residentId,
    super.residentName,
    super.room,
  });

  factory ShiftTask.fromJson(Map<String, dynamic> json) {
    return ShiftTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueAt: json['dueAt'] == null
          ? null
          : parseApiDateTime(json['dueAt'] as String),
      status: TaskStatusX.fromApiValue(json['status'] as String),
      statusNote: json['statusNote'] as String?,
      residentId: json['residentId'] as String?,
      residentName: json['residentName'] as String?,
      room: json['room'] as String?,
    );
  }

  final String? statusNote;

  String? get note => statusNote;
}
