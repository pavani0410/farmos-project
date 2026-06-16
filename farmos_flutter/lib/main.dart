import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/farms_screen.dart';
import 'screens/leaf_detection_screen.dart';

void main() {
  runApp(const FarmOSApp());
}

class FarmOSApp extends StatelessWidget {
  const FarmOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F6F3),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1B4332),
          secondary: Color(0xFF52B788),
          surface: Colors.white,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    FarmsScreen(),
    LeafDetectionScreen(),
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
              color: Colors.black.withOpacity(0.06),
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
                _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, selected: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i)),
                _NavItem(icon: Icons.agriculture_rounded, label: 'Farms', index: 1, selected: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i)),
                _NavItem(icon: Icons.biotech_rounded, label: 'Leaf AI', index: 2, selected: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i)),
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
    required this.icon, required this.label,
    required this.index, required this.selected,
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
              color: isActive ? const Color(0xFF1B4332).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon,
              size: 22,
              color: isActive ? const Color(0xFF1B4332) : Colors.grey.shade400,
            ),
          ),
          Text(label,
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