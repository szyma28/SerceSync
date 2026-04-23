import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sercesync_domain/sercesync_domain.dart';

import 'manager_file_download_api.dart';
import 'manager_theme.dart';

class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    super.key,
    required this.title,
    required this.trailingLabel,
    required this.onRefresh,
    this.statusLabel,
    this.statusIcon = Icons.schedule_rounded,
    this.isRefreshing = false,
  });

  final String title;
  final String trailingLabel;
  final Future<void> Function() onRefresh;
  final String? statusLabel;
  final IconData statusIcon;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: managerPanel,
        border: Border(bottom: BorderSide(color: managerBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: statusLabel == null
                ? const SizedBox.shrink(key: ValueKey('workspace-header-no-status'))
                : Container(
                    key: ValueKey(statusLabel),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: managerPrimarySoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: managerBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRefreshing)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(statusIcon, size: 14, color: managerPrimary),
                        const SizedBox(width: 8),
                        Text(
                          statusLabel!,
                          style: const TextStyle(
                            color: managerPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onRefresh,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF5F8FD),
              foregroundColor: managerMuted,
            ),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 14),
          Text(
            trailingLabel,
            style: const TextStyle(
              color: managerMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

void showManagerNotice(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: isError ? managerCritical : null,
      content: Text(message),
    ),
  );
}

String formatManagerFreshnessLabel(
  DateTime? lastUpdatedAt, {
  required bool isRefreshing,
  bool isLive = false,
}) {
  if (isRefreshing) {
    return isLive ? 'Refreshing live view' : 'Refreshing';
  }

  if (lastUpdatedAt == null) {
    return isLive ? 'Live view' : 'Waiting for data';
  }

  final prefix = isLive ? 'Live' : 'Updated';
  return '$prefix ${formatTimeOfDay(lastUpdatedAt)}';
}

class ComingSoonPanel extends StatelessWidget {
  const ComingSoonPanel({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(color: managerMuted, height: 1.6)),
        ],
      ),
    );
  }
}

class ErrorSurface extends StatelessWidget {
  const ErrorSurface({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: managerBorder),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: managerCritical,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class EmptySurface extends StatelessWidget {
  const EmptySurface({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: managerMuted, height: 1.5)),
        ],
      ),
    );
  }
}

String formatLongDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
}

String formatTimeOfDay(DateTime? dateTime) {
  if (dateTime == null) {
    return '--';
  }

  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String formatManagerDate(DateTime? value) {
  if (value == null) {
    return 'Not set';
  }

  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String formatManagerDateTime(DateTime value) {
  return '${formatManagerDate(value)} ${formatTimeOfDay(value)}';
}

String formatRoundLabel(String value) {
  switch (value) {
    case 'MIDDAY':
      return 'Midday';
    case 'EVENING':
      return 'Evening';
    case 'BEDTIME':
      return 'Bedtime';
    case 'CUSTOM':
      return 'Custom';
    case 'MORNING':
    default:
      return 'Morning';
  }
}

String formatAnchorLabel(String value) {
  switch (value) {
    case 'HANDOVER_ACKNOWLEDGED':
      return 'Handover acknowledged';
    case 'FIXED_TIME':
      return 'Fixed time';
    case 'SHIFT_START':
    default:
      return 'Shift start';
  }
}

String formatMedicationSource(String value) {
  switch (value) {
    case 'PHARMACY_SUPPLIED':
      return 'Pharmacy supplied';
    case 'IMPORTED':
      return 'Imported';
    case 'MANUAL_ENTRY':
    default:
      return 'Manual entry';
  }
}

String formatMedicationEventLabel(String value) {
  switch (value) {
    case 'PRN_ADMINISTERED':
      return 'PRN administered';
    case 'PRN_OFFERED':
      return 'PRN offered';
    case 'PRN_REFUSED':
      return 'PRN refused';
    case 'PRN_NOT_GIVEN':
      return 'PRN not given';
    case 'NOT_AVAILABLE':
      return 'Not available';
    default:
      return value.toLowerCase().replaceAll('_', ' ');
  }
}

String formatChartLabel(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Future<void> downloadCsvExport(
  BuildContext context, {
  required ManagerFileDownloader downloader,
  required String fileName,
  required String csv,
}) async {
  final downloadStarted = await downloader.downloadText(
    fileName: fileName,
    contents: csv,
    mimeType: 'text/csv;charset=utf-8',
  );
  if (!context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        downloadStarted
            ? 'Download started for $fileName.'
            : 'Could not start download for $fileName.',
      ),
    ),
  );
}

final List<String> residentRecognitionImageKeys = [
  for (var index = 1; index <= 30; index++)
    'resident-${index.toString().padLeft(2, '0')}',
  'resident-a',
  'resident-b',
  'resident-c',
  'resident-d',
];

String residentPhotoAssetPathForKey(String recognitionImageKey) =>
    residentPhotoAssetPath(recognitionImageKey);

String initialsForName(String fullName) {
  final parts = fullName
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .toList(growable: false);

  if (parts.isEmpty) {
    return 'SS';
  }

  if (parts.length == 1) {
    return parts.first
        .substring(0, math.min(2, parts.first.length))
        .toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

class ResidentPhotoAvatar extends StatelessWidget {
  const ResidentPhotoAvatar({
    super.key,
    required this.fullName,
    required this.recognitionImageKey,
    this.size = 44,
  });

  final String fullName;
  final String recognitionImageKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: managerPrimarySoft,
      ),
      child: Image.asset(
        residentPhotoAssetPathForKey(recognitionImageKey),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              initialsForName(fullName),
              style: TextStyle(
                color: managerPrimary,
                fontWeight: FontWeight.w800,
                fontSize: math.max(12, size * 0.28),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ManagerSkeletonBlock extends StatelessWidget {
  const ManagerSkeletonBlock({
    super.key,
    required this.height,
    this.width,
    this.radius = 12,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: managerPrimarySoft,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class ManagerSkeletonCard extends StatelessWidget {
  const ManagerSkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: managerBorder),
      ),
      child: child,
    );
  }
}

class ResidentMetaPill extends StatelessWidget {
  const ResidentMetaPill({
    super.key,
    required this.label,
    this.foreground = managerMuted,
    this.background = const Color(0xFFF0F4F8),
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
