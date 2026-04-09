import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'history_screen.dart';
import 'zones_screen.dart';
import 'tracker_settings_screen.dart';

class ViewerHomeScreen extends StatefulWidget {
  const ViewerHomeScreen({super.key});

  @override
  State<ViewerHomeScreen> createState() => _ViewerHomeScreenState();
}

class _ViewerHomeScreenState extends State<ViewerHomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    MapScreen(),
    HistoryScreen(),
    ZonesScreen(),
    TrackerSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back button (only non-map screens need header padding)
            if (_currentIndex != 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
            // Bottom navigation
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.map_outlined,
                        activeIcon: Icons.map,
                        label: 'Map',
                        isActive: _currentIndex == 0,
                        onTap: () => setState(() => _currentIndex = 0),
                      ),
                      _NavItem(
                        icon: Icons.history_outlined,
                        activeIcon: Icons.history,
                        label: 'History',
                        isActive: _currentIndex == 1,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                      _NavItem(
                        icon: Icons.radar_outlined,
                        activeIcon: Icons.radar,
                        label: 'Zones',
                        isActive: _currentIndex == 2,
                        onTap: () => setState(() => _currentIndex = 2),
                      ),
                      _NavItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings,
                        label: 'Settings',
                        isActive: _currentIndex == 3,
                        onTap: () => setState(() => _currentIndex = 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? Colors.black : const Color(0xFFCCCCCC),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.black : const Color(0xFFCCCCCC),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
