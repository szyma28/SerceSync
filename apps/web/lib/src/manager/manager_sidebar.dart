import 'package:flutter/material.dart';

import 'manager_models.dart';
import 'manager_shared.dart';
import 'manager_theme.dart';

class ManagerSidebar extends StatelessWidget {
  const ManagerSidebar({
    super.key,
    required this.user,
    required this.selectedTab,
    required this.onSelectTab,
  });

  final ManagerUser user;
  final WorkspaceTab selectedTab;
  final ValueChanged<WorkspaceTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 246,
      decoration: const BoxDecoration(
        color: managerPanel,
        border: Border(right: BorderSide(color: managerBorder)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showIllustration = constraints.maxHeight >= 680;
          final illustrationHeight = constraints.maxHeight < 760
              ? 228.0
              : constraints.maxHeight < 880
              ? 286.0
              : 326.0;
          const footerBottom = 16.0;
          const footerCardReserve = 92.0;
          const footerGap = 8.0;
          final reservedFooterHeight =
              footerBottom +
              footerCardReserve +
              (showIllustration ? illustrationHeight : 0) +
              footerGap +
              12;

          final profileCard = Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: managerBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: managerPrimarySoft,
                  foregroundColor: managerPrimary,
                  child: Text(
                    initialsForName(user.displayName),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.role.label,
                        style: TextStyle(color: managerMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xFFB7D8FF),
                          Color(0xFFD8EAFF),
                          Color(0xFFF3F9FF),
                          Color(0x00FFFFFF),
                        ],
                        stops: [0, 0.2, 0.42, 0.56],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: reservedFooterHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: Image.asset(
                                'assets/images/SerceSync Logo Icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'SerceSync',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const _SidebarSectionLabel(label: 'MANAGEMENT'),
                        const SizedBox(height: 10),
                        _SidebarNavItem(
                          icon: Icons.dashboard_outlined,
                          label: 'Dashboard',
                          isActive: selectedTab == WorkspaceTab.dashboard,
                          onTap: () => onSelectTab(WorkspaceTab.dashboard),
                        ),
                        _SidebarNavItem(
                          icon: Icons.groups_outlined,
                          label: 'Residents',
                          isActive: selectedTab == WorkspaceTab.residents,
                          onTap: () => onSelectTab(WorkspaceTab.residents),
                        ),
                        _SidebarNavItem(
                          icon: Icons.fact_check_outlined,
                          label: 'Reporting',
                          isActive: selectedTab == WorkspaceTab.compliance,
                          onTap: () => onSelectTab(WorkspaceTab.compliance),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (showIllustration)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: footerBottom + footerCardReserve + footerGap,
                  child: IgnorePointer(
                    child: SizedBox(
                      height: illustrationHeight,
                      child: Image.asset(
                        'assets/images/Nurse1.png',
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 18,
                right: 18,
                bottom: footerBottom,
                child: profileCard,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  const _SidebarSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: managerMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isActive ? managerPrimarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? managerPrimary : managerMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? managerPrimary : managerInk,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
