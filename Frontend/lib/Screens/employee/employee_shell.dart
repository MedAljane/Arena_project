import 'package:Arena/Screens/employee/employee_dashboard_screen.dart';
import 'package:Arena/Screens/employee/employee_profile_screen.dart';
import 'package:Arena/Screens/employee/employee_reservations_screen.dart';
import 'package:Arena/Screens/player/player_chat_screen.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EmployeeShell extends StatefulWidget {
  const EmployeeShell({super.key});

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _currentIndex = 0;

  // Chat screen is shared with the player — it already detects the employee
  // role and queries conversations where participantsIds.employee == profileId.
  static final _screens = <Widget>[
    const EmployeeDashboardScreen(),
    const EmployeeReservationsScreen(),
    const PlayerChatScreen(),
    const EmployeeProfileScreen(),
  ];

  static final _items = <_NavItem>[
    _NavItem(icon: FontAwesomeIcons.gaugeHigh,    label: 'Dashboard'),
    _NavItem(icon: FontAwesomeIcons.calendarCheck, label: 'Reservations'),
    _NavItem(icon: FontAwesomeIcons.message,       label: 'Chat'),
    _NavItem(icon: FontAwesomeIcons.circleUser,    label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _EmployeeNavBar(
        currentIndex: _currentIndex,
        items:        _items,
        onTap:        (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Nav bar (same visual style as Player/Manager shell) ─────────────────────

class _NavItem {
  _NavItem({required this.icon, required this.label});
  final dynamic icon;
  final String  label;
}

class _EmployeeNavBar extends StatelessWidget {
  const _EmployeeNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });
  final int           currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:  Color(0xFF122553),
        border: Border(top: BorderSide(color: Color(0xFF282828), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              final item   = items[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width:  active ? 4 : 0,
                        height: active ? 4 : 0,
                        margin: EdgeInsets.only(bottom: active ? 4 : 0),
                        decoration: const BoxDecoration(
                          color: AppColors.neonGreen, shape: BoxShape.circle),
                      ),
                      FaIcon(item.icon,
                          size:  18,
                          color: active
                              ? AppColors.neonGreen
                              : AppColors.textSecondary),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontFamily:  'Inter',
                          fontSize:    10,
                          fontWeight:  active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active
                              ? AppColors.neonGreen
                              : AppColors.textSecondary,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
