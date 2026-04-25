import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../admin_theme.dart';
import 'admin_dashboard_screen.dart';
import 'admin_surplus_screen.dart';
import 'admin_requests_screen.dart';
import 'admin_reports_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _screens = [
    AdminDashboardScreen(),
    AdminSurplusScreen(),
    AdminRequestsScreen(),
    AdminReportsScreen(),
  ];

  static const _items = [
    _NavItem(icon: Icons.dashboard_outlined,   active: Icons.dashboard,      label: 'Dashboard'),
    _NavItem(icon: Icons.inventory_2_outlined, active: Icons.inventory_2,    label: 'Surplus'),
    _NavItem(icon: Icons.pending_outlined,     active: Icons.pending,        label: 'Requests'),
    _NavItem(icon: Icons.flag_outlined,        active: Icons.flag,           label: 'Reports',
        isAlert: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.theme,
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: _buildNav(),
      ),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AdminColors.navy,
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: _items.asMap().entries.map((e) {
              final i    = e.key;
              final item = e.value;
              final active = i == _index;
              final color  = item.isAlert
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFF74C69D);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _index = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? color.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(active ? item.active : item.icon,
                              size: 22,
                              color: active
                                  ? color
                                  : Colors.white.withOpacity(0.4)),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: active
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text(item.label,
                                        style: GoogleFonts.syne(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: color)),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 2),
                      if (!active)
                        Text(item.label, style: GoogleFonts.syne(
                            fontSize: 9,
                            color: Colors.white.withOpacity(0.35))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData active;
  final String label;
  final bool isAlert;
  const _NavItem({required this.icon, required this.active,
      required this.label, this.isAlert = false});
}
