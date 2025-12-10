import 'dart:math';
import 'package:flutter/material.dart';
import '../app_theme.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.animationController,
    required this.items,
    this.onLogout,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeToggle;
  final AnimationController animationController;
  final List<NavItem> items;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.isDark
              ? const [Color(0xFF0F172A), Color(0xFF115E59)]
              : const [Color(0xFF34D399), Color(0xFF6EE7B7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: animationController.value * 2 * pi,
                      child: Icon(
                        Icons.medical_services_outlined,
                        size: 50,
                        color: palette.isDark ? Colors.white : Colors.black87,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'PHARMAXY',
                  style: TextStyle(
                    color: palette.isDark ? Colors.white : Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: palette.isDark ? Colors.white24 : Colors.black12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: palette.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.brightness_6_outlined,
                    color: palette.isDark ? Colors.white : Colors.black87,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isDarkMode ? 'Thème sombre' : 'Thème clair',
                      style: TextStyle(
                        color: palette.isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: isDarkMode,
                    activeColor: Colors.tealAccent,
                    onChanged: onThemeToggle,
                  ),
                ],
              ),
            ),
          ),
          Divider(color: palette.isDark ? Colors.white24 : Colors.black12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;
                final baseColor = palette.isDark
                    ? Colors.white70
                    : Colors.black54;
                final selectedColor = palette.isDark
                    ? Colors.white
                    : Colors.black87;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (palette.isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.black.withOpacity(0.08))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected ? selectedColor : baseColor,
                        size: 28,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? selectedColor : baseColor,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () => onItemSelected(index),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Container(
              decoration: BoxDecoration(
                color: palette.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.logout,
                  color: palette.isDark ? Colors.white : Colors.black87,
                ),
                title: Text(
                  'Déconnexion',
                  style: TextStyle(
                    color: palette.isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: palette.isDark ? Colors.white54 : Colors.black45,
                  size: 14,
                ),
                onTap: onLogout,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NavItem {
  const NavItem({required this.icon, required this.label, this.id});

  final String? id;
  final IconData icon;
  final String label;
}
