part of '../../manager_app.dart';

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview({
    super.key,
    required this.dashboard,
    required this.activeShifts,
    required this.selectedShiftId,
    required this.isLoading,
    required this.errorMessage,
    required this.onShiftSelected,
    required this.pendingIncidentIds,
    required this.onAcknowledgeIncident,
    required this.onResolveIncident,
  });

  final ManagerDashboardSnapshot? dashboard;
  final List<ManagerShiftSummary> activeShifts;
  final String? selectedShiftId;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onShiftSelected;
  final Set<String> pendingIncidentIds;
  final Future<void> Function(String incidentId) onAcknowledgeIncident;
  final Future<void> Function(String incidentId) onResolveIncident;

  @override
  Widget build(BuildContext context) {
    if (isLoading && dashboard == null) {
      return const SizedBox(
        height: 380,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null && dashboard == null) {
      return _ErrorSurface(message: errorMessage!);
    }

    if (activeShifts.isEmpty) {
      return const _DashboardEmptyState();
    }

    final data = dashboard;
    if (data == null) {
      return const _ErrorSurface(
        message: 'The dashboard returned without any overview data.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final metricColumns = constraints.maxWidth >= 1120
            ? 5
            : constraints.maxWidth >= 760
            ? 2
            : 1;
        final metricSpacing = 16.0;
        final metricCardWidth =
            (constraints.maxWidth - (metricSpacing * (metricColumns - 1))) /
            metricColumns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardShiftScopeCard(
              activeShifts: activeShifts,
              selectedShiftId: selectedShiftId ?? data.activeShift.id,
              activeShift: data.activeShift,
              onShiftSelected: onShiftSelected,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: metricSpacing,
              runSpacing: metricSpacing,
              children: [
                SizedBox(
                  width: metricCardWidth,
                  child: _MetricCard(
                    icon: Icons.emergency_outlined,
                    toneColor: _managerCritical,
                    toneBackground: _managerCriticalSoft,
                    label: 'ACTIVE INCIDENTS',
                    value: data.metrics.activeIncidents.toString(),
                    note: data.metrics.activeIncidents == 0
                        ? 'No unresolved incidents'
                        : 'Immediate follow-up required',
                  ),
                ),
                SizedBox(
                  width: metricCardWidth,
                  child: _MetricCard(
                    icon: Icons.schedule_rounded,
                    toneColor: _managerCritical,
                    toneBackground: _managerCriticalSoft,
                    label: 'OVERDUE TASKS',
                    value: data.metrics.overdueTasks.toString(),
                    note: data.metrics.overdueTasks == 0
                        ? 'No missed care windows'
                        : 'Need review now',
                  ),
                ),
                SizedBox(
                  width: metricCardWidth,
                  child: _MetricCard(
                    icon: Icons.priority_high_rounded,
                    toneColor: _managerWarning,
                    toneBackground: _managerWarningSoft,
                    label: 'ESCALATED ITEMS',
                    value: data.metrics.escalatedItems.toString(),
                    note: data.metrics.escalatedItems == 0
                        ? 'No escalations logged'
                        : 'Requires attention',
                  ),
                ),
                SizedBox(
                  width: metricCardWidth,
                  child: _MetricCard(
                    icon: Icons.groups_2_outlined,
                    toneColor: _managerInfo,
                    toneBackground: _managerInfoSoft,
                    label: 'UNREAD HANDOVERS',
                    value: data.metrics.unreadHandovers.toString(),
                    note: data.metrics.unreadHandovers == 0
                        ? 'All staff confirmed'
                        : 'Awaiting confirmation',
                  ),
                ),
                SizedBox(
                  width: metricCardWidth,
                  child: _MetricCard(
                    icon: Icons.check_circle_outline_rounded,
                    toneColor: _managerSuccess,
                    toneBackground: _managerSuccessSoft,
                    label: 'SHIFT COMPLETION',
                    value: '${data.metrics.shiftCompletionPercent}%',
                    note:
                        'On track for ${_formatTimeOfDay(data.activeShift.endsAt)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _LiveExceptionFeedCard(
              items: data.exceptionFeed,
              unitLabel: data.activeShift.unitLabel,
              pendingIncidentIds: pendingIncidentIds,
              onAcknowledgeIncident: onAcknowledgeIncident,
              onResolveIncident: onResolveIncident,
            ),
            const SizedBox(height: 18),
            _LiveActivityFeedCard(
              items: data.activityFeed,
              unitLabel: data.activeShift.unitLabel,
            ),
            const SizedBox(height: 18),
            _ComplianceCard(points: data.complianceSeries),
          ],
        );
      },
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _managerPanel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'No active shifts available yet.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text(
            'Start an active shift for a unit to unlock the manager overview, incident feed, and live compliance signals.',
            style: TextStyle(color: _managerMuted, height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _DashboardShiftScopeCard extends StatelessWidget {
  const _DashboardShiftScopeCard({
    required this.activeShifts,
    required this.selectedShiftId,
    required this.activeShift,
    required this.onShiftSelected,
  });

  final List<ManagerShiftSummary> activeShifts;
  final String selectedShiftId;
  final ManagerShiftSummary activeShift;
  final ValueChanged<String> onShiftSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _managerBorder),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 260, maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Shift Scope',
                  style: TextStyle(
                    color: _managerMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activeShift.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${activeShift.unitLabel} • Floor ${activeShift.floorNumber}',
                  style: const TextStyle(color: _managerMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (activeShifts.length > 1)
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<String>(
                key: ValueKey('dashboard-shift-selector-$selectedShiftId'),
                initialValue: selectedShiftId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Dashboard Shift'),
                items: activeShifts
                    .map(
                      (shift) => DropdownMenuItem(
                        value: shift.id,
                        child: Text('${shift.unitLabel} • ${shift.name}'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    onShiftSelected(value);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.toneColor,
    required this.toneBackground,
    required this.label,
    required this.value,
    required this.note,
  });

  final IconData icon;
  final Color toneColor;
  final Color toneBackground;
  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _managerPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _managerBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: toneBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: toneColor, size: 18),
              ),
              const Spacer(),
              Icon(Icons.arrow_outward_rounded, size: 16, color: toneColor),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            label,
            style: const TextStyle(
              color: _managerMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(
              color: _managerMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveExceptionFeedCard extends StatelessWidget {
  const _LiveExceptionFeedCard({
    required this.items,
    required this.unitLabel,
    required this.pendingIncidentIds,
    required this.onAcknowledgeIncident,
    required this.onResolveIncident,
  });

  final List<ManagerExceptionFeedItem> items;
  final String unitLabel;
  final Set<String> pendingIncidentIds;
  final Future<void> Function(String incidentId) onAcknowledgeIncident;
  final Future<void> Function(String incidentId) onResolveIncident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Live Exception Feed',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFD),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _managerBorder),
              ),
              child: Text(
                'No active exceptions in $unitLabel right now. The feed will populate as incidents, overdue tasks, escalations, or due-soon tasks appear.',
                style: const TextStyle(color: _managerMuted, height: 1.55),
              ),
            )
          else
            Column(
              children: [
                for (final item in items) ...[
                  _ExceptionFeedRow(
                    key: ValueKey('exception-row-${item.id}'),
                    item: item,
                    isActionPending: pendingIncidentIds.contains(item.id),
                    onAcknowledgeIncident: onAcknowledgeIncident,
                    onResolveIncident: onResolveIncident,
                  ),
                  if (item != items.last) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _LiveActivityFeedCard extends StatelessWidget {
  const _LiveActivityFeedCard({required this.items, required this.unitLabel});

  final List<ManagerActivityFeedItem> items;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Activity Feed',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFD),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _managerBorder),
              ),
              child: Text(
                'No recent notes, task updates, or incident actions in $unitLabel yet. This feed refreshes automatically so managers can follow care activity as it happens.',
                style: const TextStyle(color: _managerMuted, height: 1.55),
              ),
            )
          else
            Column(
              children: [
                for (final item in items) ...[
                  _ActivityFeedRow(
                    key: ValueKey('activity-row-${item.id}'),
                    item: item,
                  ),
                  if (item != items.last) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ExceptionFeedRow extends StatelessWidget {
  const _ExceptionFeedRow({
    super.key,
    required this.item,
    required this.isActionPending,
    required this.onAcknowledgeIncident,
    required this.onResolveIncident,
  });

  final ManagerExceptionFeedItem item;
  final bool isActionPending;
  final Future<void> Function(String incidentId) onAcknowledgeIncident;
  final Future<void> Function(String incidentId) onResolveIncident;

  @override
  Widget build(BuildContext context) {
    final tone = _exceptionToneFor(item.badgeTone);
    final kindTone = _feedKindToneFor(item.kind);
    final timeLabel = _formatTimeOfDay(item.occurredAt ?? item.dueAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _managerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tone.icon, size: 18, color: tone.foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        color: _managerMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.residentName} • ${item.roomLabel}',
                  style: const TextStyle(color: _managerMuted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: _managerInk,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _FeedBadge(
                      label: item.kind == ManagerExceptionKind.incident
                          ? 'INCIDENT'
                          : 'TASK',
                      foreground: kindTone.foreground,
                      background: kindTone.background,
                    ),
                    _FeedBadge(
                      label: item.badge,
                      foreground: tone.foreground,
                      background: tone.background,
                    ),
                    _FeedBadge(
                      label: item.status.label.toUpperCase(),
                      foreground: _managerMuted,
                      background: const Color(0xFFF0F4F8),
                    ),
                    if (item.isIncident && item.severity != null)
                      _FeedBadge(
                        label: item.severity!.label.toUpperCase(),
                        foreground: item.severity == ManagerIncidentSeverity.red
                            ? _managerCritical
                            : _managerWarning,
                        background: item.severity == ManagerIncidentSeverity.red
                            ? _managerCriticalSoft
                            : _managerWarningSoft,
                      ),
                  ],
                ),
                if (item.isIncident &&
                    (item.canAcknowledge || item.canResolve)) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (item.canAcknowledge)
                        OutlinedButton(
                          onPressed: isActionPending
                              ? null
                              : () => onAcknowledgeIncident(item.id),
                          child: isActionPending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Acknowledge'),
                        ),
                      if (item.canResolve)
                        FilledButton.tonal(
                          onPressed: isActionPending
                              ? null
                              : () => onResolveIncident(item.id),
                          style: FilledButton.styleFrom(
                            foregroundColor: _managerPrimary,
                            backgroundColor: _managerPrimarySoft,
                          ),
                          child: isActionPending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Resolve'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityFeedRow extends StatelessWidget {
  const _ActivityFeedRow({super.key, required this.item});

  final ManagerActivityFeedItem item;

  @override
  Widget build(BuildContext context) {
    final tone = _exceptionToneFor(item.badgeTone);
    final kindTone = _activityKindToneFor(item.kind);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _managerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tone.icon, size: 18, color: tone.foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatTimeOfDay(item.occurredAt),
                      style: const TextStyle(
                        color: _managerMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.residentName} • ${item.roomLabel}',
                  style: const TextStyle(color: _managerMuted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: _managerInk,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _FeedBadge(
                      label: switch (item.kind) {
                        ManagerActivityKind.note => 'NOTE',
                        ManagerActivityKind.task => 'TASK',
                        ManagerActivityKind.incident => 'INCIDENT',
                      },
                      foreground: kindTone.foreground,
                      background: kindTone.background,
                    ),
                    _FeedBadge(
                      label: item.badge,
                      foreground: tone.foreground,
                      background: tone.background,
                    ),
                    Text(
                      'Updated by ${item.actorName}',
                      style: const TextStyle(
                        color: _managerMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedBadge extends StatelessWidget {
  const _FeedBadge({
    required this.label,
    required this.foreground,
    required this.background,
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
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({required this.points});

  final List<ManagerCompliancePoint> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Task Compliance %',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const Icon(Icons.timeline_rounded, color: _managerMuted),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '100',
                      style: TextStyle(color: _managerMuted, fontSize: 11),
                    ),
                    Text(
                      '90',
                      style: TextStyle(color: _managerMuted, fontSize: 11),
                    ),
                    Text(
                      '80',
                      style: TextStyle(color: _managerMuted, fontSize: 11),
                    ),
                    Text(
                      '70',
                      style: TextStyle(color: _managerMuted, fontSize: 11),
                    ),
                    Text(
                      '60',
                      style: TextStyle(color: _managerMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomPaint(
                          painter: _ComplianceChartPainter(points: points),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final point in points)
                            Text(
                              _formatChartLabel(point.timestamp),
                              style: const TextStyle(
                                color: _managerMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplianceChartPainter extends CustomPainter {
  const _ComplianceChartPainter({required this.points});

  final List<ManagerCompliancePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const minValue = 60.0;
    const maxValue = 100.0;

    final gridPaint = Paint()
      ..color = _managerBorder
      ..strokeWidth = 1;

    for (var index = 0; index < 5; index++) {
      final y = size.height * (index / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) {
      return;
    }

    final spacing = points.length == 1 ? 0.0 : size.width / (points.length - 1);
    final chartPoints = <Offset>[];

    for (var index = 0; index < points.length; index++) {
      final value = points[index].value.toDouble();
      final normalized = ((value - minValue) / (maxValue - minValue)).clamp(
        0.0,
        1.0,
      );
      final dx = spacing * index;
      final dy = size.height - (normalized * size.height);
      chartPoints.add(Offset(dx, dy));
    }

    final linePath = Path()..moveTo(chartPoints.first.dx, chartPoints.first.dy);
    for (var index = 1; index < chartPoints.length; index++) {
      final previous = chartPoints[index - 1];
      final current = chartPoints[index];
      final controlPoint1 = Offset((previous.dx + current.dx) / 2, previous.dy);
      final controlPoint2 = Offset((previous.dx + current.dx) / 2, current.dy);
      linePath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        current.dx,
        current.dy,
      );
    }

    final areaPath = Path.from(linePath)
      ..lineTo(chartPoints.last.dx, size.height)
      ..lineTo(chartPoints.first.dx, size.height)
      ..close();

    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x554B78FF), Color(0x004B78FF)],
      ).createShader(Offset.zero & size);

    final linePaint = Paint()
      ..color = _managerPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(linePath, linePaint);

    final markerPaint = Paint()..color = _managerPrimary;
    final markerFillPaint = Paint()..color = Colors.white;
    for (final point in chartPoints) {
      canvas.drawCircle(point, 4.5, markerFillPaint);
      canvas.drawCircle(point, 3.0, markerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ComplianceChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _ExceptionTone {
  const _ExceptionTone({
    required this.foreground,
    required this.background,
    required this.icon,
  });

  final Color foreground;
  final Color background;
  final IconData icon;
}

_ExceptionTone _feedKindToneFor(ManagerExceptionKind kind) {
  switch (kind) {
    case ManagerExceptionKind.incident:
      return const _ExceptionTone(
        foreground: _managerPrimary,
        background: _managerPrimarySoft,
        icon: Icons.emergency_outlined,
      );
    case ManagerExceptionKind.task:
      return const _ExceptionTone(
        foreground: _managerInfo,
        background: _managerInfoSoft,
        icon: Icons.checklist_rounded,
      );
  }
}

_ExceptionTone _activityKindToneFor(ManagerActivityKind kind) {
  switch (kind) {
    case ManagerActivityKind.note:
      return const _ExceptionTone(
        foreground: _managerInfo,
        background: _managerInfoSoft,
        icon: Icons.sticky_note_2_outlined,
      );
    case ManagerActivityKind.task:
      return const _ExceptionTone(
        foreground: _managerSuccess,
        background: _managerSuccessSoft,
        icon: Icons.task_alt_rounded,
      );
    case ManagerActivityKind.incident:
      return const _ExceptionTone(
        foreground: _managerWarning,
        background: _managerWarningSoft,
        icon: Icons.health_and_safety_outlined,
      );
  }
}

_ExceptionTone _exceptionToneFor(String tone) {
  switch (tone) {
    case 'critical':
      return const _ExceptionTone(
        foreground: _managerCritical,
        background: _managerCriticalSoft,
        icon: Icons.warning_amber_rounded,
      );
    case 'warning':
      return const _ExceptionTone(
        foreground: _managerWarning,
        background: _managerWarningSoft,
        icon: Icons.priority_high_rounded,
      );
    case 'success':
      return const _ExceptionTone(
        foreground: _managerSuccess,
        background: _managerSuccessSoft,
        icon: Icons.check_circle_outline_rounded,
      );
    case 'info':
    default:
      return const _ExceptionTone(
        foreground: _managerInfo,
        background: _managerInfoSoft,
        icon: Icons.schedule_rounded,
      );
  }
}
