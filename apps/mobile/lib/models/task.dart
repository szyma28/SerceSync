class ShiftTask {
  const ShiftTask({
    required this.id,
    required this.title,
    this.description,
    this.dueAt,
    required this.status,
    this.note,
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
          : DateTime.parse(json['dueAt'] as String),
      status: json['status'] as String,
      note: json['note'] as String?,
      residentName: json['residentName'] as String?,
      room: json['room'] as String?,
    );
  }

  final String id;
  final String title;
  final String? description;
  final DateTime? dueAt;
  final String status;
  final String? note;
  final String? residentName;
  final String? room;
}
