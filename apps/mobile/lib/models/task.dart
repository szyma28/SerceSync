import 'shared_models.dart';

class ShiftTask extends TaskRecord {
  const ShiftTask({
    required super.id,
    required super.title,
    super.description,
    super.dueAt,
    required super.status,
    super.focus,
    super.clinicalPriority,
    this.statusNote,
    super.residentId,
    super.residentName,
    super.room,
    super.canComplete,
    super.canDefer,
    super.canEscalate,
    super.actionRestrictionReason,
  });

  factory ShiftTask.fromJson(Map<String, dynamic> json) {
    return ShiftTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueAt: json['dueAt'] == null
          ? null
          : parseApiDateTime(json['dueAt'] as String),
      focus: json['focus'] == null
          ? TaskFocus.general
          : TaskFocusX.fromApiValue(json['focus'] as String),
      clinicalPriority: json['clinicalPriority'] == null
          ? TaskClinicalPriority.routine
          : TaskClinicalPriorityX.fromApiValue(
              json['clinicalPriority'] as String,
            ),
      status: TaskStatusX.fromApiValue(json['status'] as String),
      statusNote: json['statusNote'] as String?,
      residentId: json['residentId'] as String?,
      residentName: json['residentName'] as String?,
      room: json['room'] as String?,
      canComplete: json['canComplete'] as bool?,
      canDefer: json['canDefer'] as bool?,
      canEscalate: json['canEscalate'] as bool?,
      actionRestrictionReason: json['actionRestrictionReason'] as String?,
    );
  }

  final String? statusNote;

  String? get note => statusNote;
}
