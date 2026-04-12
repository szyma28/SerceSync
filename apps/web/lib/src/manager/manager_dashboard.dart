part of '../../manager_app.dart';

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview({
    super.key,
    required this.dashboard,
    required this.isLoading,
    required this.errorMessage,
  });

  final ManagerDashboardSnapshot? dashboard;
  final bool isLoading;
  final String? errorMessage;

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

    final data = dashboard;
    if (data == null) {
      return const _ErrorSurface(
        message: 'The dashboard returned without any overview data.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final metricColumns = constraints.maxWidth >= 1120
            ? 4
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
            Wrap(
              spacing: metricSpacing,
              runSpacing: metricSpacing,
              children: [
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
            ),
            const SizedBox(height: 18),
            _ComplianceCard(points: data.complianceSeries),
          ],
        );
      },
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
  const _LiveExceptionFeedCard({required this.items, required this.unitLabel});

  final List<ManagerExceptionFeedItem> items;
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
                'No active exceptions in $unitLabel right now. The feed will populate as tasks become overdue, escalated, or due soon.',
                style: const TextStyle(color: _managerMuted, height: 1.55),
              ),
            )
          else
            Column(
              children: [
                for (final item in items) ...[
                  _ExceptionFeedRow(item: item),
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
  const _ExceptionFeedRow({required this.item});

  final ManagerExceptionFeedItem item;

  @override
  Widget build(BuildContext context) {
    final tone = _exceptionToneFor(item.badgeTone);

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
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.residentName} • ${item.roomLabel}',
                  style: const TextStyle(color: _managerMuted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  '“${item.description}”',
                  style: const TextStyle(
                    color: _managerInk,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTimeOfDay(item.dueAt),
                style: const TextStyle(
                  color: _managerMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tone.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.badge,
                  style: TextStyle(
                    color: tone.foreground,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
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

_ExceptionTone _exceptionToneFor(String tone) {
  switch (tone) {
    case 'critical':
      return const _ExceptionTone(
        foreground: _managerCritical,
        background: _managerCriticalSoft,
        icon: Icons.close_rounded,
      );
    case 'warning':
      return const _ExceptionTone(
        foreground: _managerWarning,
        background: _managerWarningSoft,
        icon: Icons.arrow_outward_rounded,
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
