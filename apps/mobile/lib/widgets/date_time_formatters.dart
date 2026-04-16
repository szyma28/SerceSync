String formatDayMonthHourMinute(DateTime value) {
  return '${_twoDigits(value.day)}/${_twoDigits(value.month)} ${formatHourMinute(value)}';
}

String formatHourMinute(DateTime value) {
  return '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
}

String formatHourMinuteRange(
  DateTime start,
  DateTime end, {
  String separator = ' - ',
}) {
  return '${formatHourMinute(start)}$separator${formatHourMinute(end)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
