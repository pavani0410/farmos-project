import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/farms_screen.dart';
import 'screens/leaf_detection_screen.dart';

class AppShell extends StatefulWidget {
  final int userId;
  final String username;

  const AppShell({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    DashboardScreen(userId: widget.userId, username: widget.username),
    FarmsScreen(userId: widget.userId, username: widget.username),
    const LeafDetectionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                  selected: _selectedIndex,
                  onTap: (i) => setState(() => _selectedIndex = i),
                ),
                _NavItem(
                  icon: Icons.agriculture_rounded,
                  label: 'Farms',
                  index: 1,
                  selected: _selectedIndex,
                  onTap: (i) => setState(() => _selectedIndex = i),
                ),
                _NavItem(
                  icon: Icons.biotech_rounded,
                  label: 'Leaf AI',
                  index: 2,
                  selected: _selectedIndex,
                  onTap: (i) => setState(() => _selectedIndex = i),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selected;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == selected;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF1B4332).withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isActive ? const Color(0xFF1B4332) : Colors.grey.shade400,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? const Color(0xFF1B4332) : Colors.grey.shade400,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
