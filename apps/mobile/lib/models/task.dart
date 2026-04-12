DateTime _parseApiDateTime(String value) => DateTime.parse(value).toLocal();

class ShiftTask {
  const ShiftTask({
    required this.id,
    required this.title,
    this.description,
    this.dueAt,
    required this.status,
    this.statusNote,
    this.residentId,
    this.residentName,
    this.room,
  });

  factory ShiftTask.fromJson(Map<String, dynamic> json) {
    return ShiftTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueAt: json['dueAt'] == null
          ? null
          : _parseApiDateTime(json['dueAt'] as String),
      status: json['status'] as String,
      statusNote: json['statusNote'] as String?,
      residentId: json['residentId'] as String?,
      residentName: json['residentName'] as String?,
      room: json['room'] as String?,
    );
  }

  final String id;
  final String title;
  final String? description;
  final DateTime? dueAt;
  final String status;
  final String? statusNote;
  final String? residentId;
  final String? residentName;
  final String? room;

  String? get note => statusNote;
}
