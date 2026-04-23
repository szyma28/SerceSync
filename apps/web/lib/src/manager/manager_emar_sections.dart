part of 'manager_emar.dart';

class _EmarChartSummaryCard extends StatelessWidget {
  const _EmarChartSummaryCard({
    required this.resident,
    required this.chart,
    required this.safetyBanner,
  });

  final ManagerResidentRecord resident;
  final ManagerMedicationChartSummary? chart;
  final String safetyBanner;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ResidentMetaPill(label: resident.roomLabel),
              ResidentMetaPill(label: resident.unitLabel),
              ResidentMetaPill(label: 'Floor ${resident.floorNumber}'),
              ResidentMetaPill(
                label: chart == null ? 'Chart pending' : chart!.status,
                foreground: chart == null ? managerWarning : managerSuccess,
                background: chart == null
                    ? managerWarningSoft
                    : managerSuccessSoft,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            safetyBanner,
            style: const TextStyle(
              color: managerCritical,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          if (chart == null)
            const Text(
              'The medication chart will be created automatically when the first medication order is entered.',
              style: TextStyle(color: managerMuted, height: 1.5),
            )
          else
            Wrap(
              spacing: 18,
              runSpacing: 12,
              children: [
                _EmarKeyValue(
                  label: 'Created',
                  value: formatManagerDateTime(chart!.createdAt),
                ),
                _EmarKeyValue(
                  label: 'Created by',
                  value: chart!.createdByUserName ?? 'Unknown user',
                ),
                _EmarKeyValue(
                  label: 'Reviewed by',
                  value: chart!.reviewedByUserName ?? 'Not recorded',
                ),
                _EmarKeyValue(
                  label: 'Last updated',
                  value: formatManagerDateTime(chart!.updatedAt),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmarAllergySection extends StatelessWidget {
  const _EmarAllergySection({
    required this.allergies,
    required this.onAddAllergy,
  });

  final List<ManagerMedicationAllergyRecord> allergies;
  final VoidCallback? onAddAllergy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: managerCriticalSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Allergies & intolerances',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAddAllergy,
                icon: const Icon(Icons.add_alert_outlined),
                label: const Text('Record allergy'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (allergies.isEmpty)
            const Text(
              'No allergies or intolerances are recorded for this resident.',
              style: TextStyle(color: managerMuted, height: 1.5),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final allergy in allergies)
                  Container(
                    width: 300,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: managerBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          allergy.substance,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if ((allergy.reaction ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Reaction: ${allergy.reaction}',
                            style: const TextStyle(color: managerMuted),
                          ),
                        ],
                        if ((allergy.severity ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Severity: ${allergy.severity}',
                            style: const TextStyle(color: managerMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmarMedicationSection extends StatelessWidget {
  const _EmarMedicationSection({
    required this.title,
    required this.emptyTitle,
    required this.emptyBody,
    required this.children,
  });

  final String title;
  final String emptyTitle;
  final String emptyBody;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          if (children.isEmpty)
            EmptySurface(title: emptyTitle, body: emptyBody)
          else
            ...children,
        ],
      ),
    );
  }
}

class _EmarMedicationOrderCard extends StatelessWidget {
  const _EmarMedicationOrderCard({
    required this.order,
    required this.onEdit,
    required this.onDeactivate,
    required this.onAddSchedule,
    required this.onAddPrnProtocol,
    required this.onRecordStock,
  });

  final ManagerMedicationOrderRecord order;
  final VoidCallback? onEdit;
  final VoidCallback? onDeactivate;
  final VoidCallback? onAddSchedule;
  final VoidCallback? onAddPrnProtocol;
  final VoidCallback? onRecordStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.titleLine,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${order.doseLine} • ${formatMedicationSource(order.sourceType)}',
                      style: const TextStyle(color: managerMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.instructions,
                      style: const TextStyle(color: managerInk, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: onEdit,
                    child: const Text('Edit'),
                  ),
                  if (!order.isPrn)
                    OutlinedButton(
                      onPressed: onAddSchedule,
                      child: const Text('Add schedule'),
                    ),
                  if (order.isPrn)
                    OutlinedButton(
                      onPressed: onAddPrnProtocol,
                      child: Text(
                        order.prnProtocol == null
                            ? 'Add PRN protocol'
                            : 'Replace PRN protocol',
                      ),
                    ),
                  OutlinedButton(
                    onPressed: onRecordStock,
                    child: Text(
                      order.stock == null ? 'Record stock' : 'Update stock',
                    ),
                  ),
                  if (order.isActive)
                    OutlinedButton(
                      onPressed: onDeactivate,
                      child: const Text('Deactivate'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ResidentMetaPill(
                label: order.isActive ? 'Active' : 'Inactive',
                foreground: order.isActive ? managerSuccess : managerMuted,
                background: order.isActive
                    ? managerSuccessSoft
                    : const Color(0xFFF0F4F8),
              ),
              ResidentMetaPill(
                label: order.isPrn ? 'PRN' : 'Scheduled',
                foreground: order.isPrn ? managerWarning : managerPrimary,
                background: order.isPrn
                    ? managerWarningSoft
                    : managerPrimarySoft,
              ),
              if (order.isControlledDrug)
                const ResidentMetaPill(
                  label: 'Controlled drug',
                  foreground: managerCritical,
                  background: managerCriticalSoft,
                ),
              if (order.requiresWitness)
                const ResidentMetaPill(
                  label: 'Witness required',
                  foreground: managerCritical,
                  background: managerCriticalSoft,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 12,
            children: [
              _EmarKeyValue(label: 'Route', value: order.route),
              _EmarKeyValue(
                label: 'Start',
                value: formatManagerDate(order.startDate),
              ),
              _EmarKeyValue(
                label: 'End',
                value: formatManagerDate(order.endDate),
              ),
              _EmarKeyValue(
                label: 'Updated',
                value: formatManagerDateTime(order.updatedAt),
              ),
            ],
          ),
          if (order.schedules.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Schedules',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final schedule in order.schedules)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: managerBorder),
                    ),
                    child: Text(
                      '${formatRoundLabel(schedule.roundLabel)} • ${formatAnchorLabel(schedule.anchorType)}'
                      '${schedule.fixedTimeLocal == null ? '' : ' • ${schedule.fixedTimeLocal}'}'
                      '${schedule.windowEndOffsetMinutes == null ? '' : ' • ${schedule.windowStartOffsetMinutes ?? 0}-${schedule.windowEndOffsetMinutes} min'}',
                      style: const TextStyle(color: managerMuted),
                    ),
                  ),
              ],
            ),
          ],
          if (order.prnProtocol != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: managerWarningSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: managerBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRN protocol: ${order.prnProtocol!.indication}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.prnProtocol!.whenToOffer,
                    style: const TextStyle(color: managerMuted, height: 1.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dose instructions: ${order.prnProtocol!.doseInstructions}',
                    style: const TextStyle(color: managerMuted, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
          if (order.stock != null) ...[
            const SizedBox(height: 14),
            Text(
              'Stock: ${order.stock!.currentQuantity} ${order.stock!.quantityUnit}'
              '${order.stock!.lastCheckedAt == null ? '' : ' • checked ${formatManagerDateTime(order.stock!.lastCheckedAt!)}'}',
              style: const TextStyle(color: managerMuted),
            ),
          ],
          if ((order.deactivationReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Deactivation reason: ${order.deactivationReason}',
              style: const TextStyle(color: managerCritical),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmarRecentEventsSection extends StatelessWidget {
  const _EmarRecentEventsSection({required this.events});

  final List<ManagerMedicationAdministrationRecord> events;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent administration events',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          if (events.isEmpty)
            const EmptySurface(
              title: 'No medication events recorded yet',
              body:
                  'Administration outcomes, PRN records, and medication exceptions will appear here.',
            )
          else
            for (final event in events.take(12)) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(event.medicationLabel),
                subtitle: Text(
                  '${formatMedicationEventLabel(event.eventType)} • ${event.reason ?? 'No reason recorded'}',
                ),
                trailing: Text(formatManagerDateTime(event.recordedAt)),
              ),
              if (event != events.take(12).last)
                const Divider(height: 1, color: managerBorder),
            ],
        ],
      ),
    );
  }
}

class _EmarStockSection extends StatelessWidget {
  const _EmarStockSection({
    required this.stockOverview,
    required this.orders,
    required this.onRecordStock,
  });

  final List<ManagerMedicationStockSummary> stockOverview;
  final List<ManagerMedicationOrderRecord> orders;
  final Future<void> Function(ManagerMedicationOrderRecord order)?
  onRecordStock;

  @override
  Widget build(BuildContext context) {
    final orderByStockId = <String, ManagerMedicationOrderRecord>{
      for (final order in orders)
        if (order.stock != null) order.stock!.id: order,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock overview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          if (stockOverview.isEmpty)
            const EmptySurface(
              title: 'No stock entries',
              body:
                  'Stock entries will appear here after balances or checks are recorded.',
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final stock in stockOverview)
                  Container(
                    width: 280,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBFE),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: managerBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderByStockId[stock.id]?.titleLine ??
                              'Medication stock',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: managerInk,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${stock.currentQuantity} ${stock.quantityUnit}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stock.notes ?? 'No stock note recorded.',
                          style: const TextStyle(
                            color: managerMuted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stock.lastCheckedAt == null
                              ? 'Last checked: not recorded'
                              : 'Last checked: ${formatManagerDateTime(stock.lastCheckedAt!)}',
                          style: const TextStyle(color: managerMuted),
                        ),
                        if (stock.lastCheckedByUserName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Checked by: ${stock.lastCheckedByUserName}',
                            style: const TextStyle(color: managerMuted),
                          ),
                        ],
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                orderByStockId[stock.id] == null ||
                                    onRecordStock == null
                                ? null
                                : () =>
                                      onRecordStock!(orderByStockId[stock.id]!),
                            icon: const Icon(Icons.inventory_2_outlined),
                            label: const Text('Record stock update'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmarChangeHistorySection extends StatelessWidget {
  const _EmarChangeHistorySection({required this.changeHistory});

  final List<ManagerMedicationChangeLogRecord> changeHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change history',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          if (changeHistory.isEmpty)
            const EmptySurface(
              title: 'No medication changes recorded',
              body:
                  'Medication creation, edits, deactivation, and PRN/schedule changes will be listed here.',
            )
          else
            for (final change in changeHistory.take(12)) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${change.medicationName} • ${_formatMedicationChangeType(change.changeType)}',
                ),
                subtitle: Text(
                  '${change.changedByUserName ?? 'Unknown user'} • ${change.reason}',
                ),
                trailing: Text(formatManagerDateTime(change.createdAt)),
              ),
              if (change != changeHistory.take(12).last)
                const Divider(height: 1, color: managerBorder),
            ],
        ],
      ),
    );
  }
}

class _EmarKeyValue extends StatelessWidget {
  const _EmarKeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: managerMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
