import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:gogreen_admin/providers/theme_provider.dart';

class Sidebar extends StatefulWidget {
  final String currentRoute;
  final bool isCollapsed;

  const Sidebar({
    super.key,
    required this.currentRoute,
    this.isCollapsed = false,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isCollapsed;
  }

  final List<SidebarItem> _items = [
    SidebarItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    SidebarItem(
      icon: Icons.directions_car,
      label: 'CoreVehicles',
      route: '/coreVehicles',
    ),
    SidebarItem(
      icon: Icons.build,
      label: 'Jobs',
      route: '/jobs',
    ),
    SidebarItem(
      icon: Icons.analytics,
      label: 'Analytics',
      route: '/analytics',
    ),
    SidebarItem(
      icon: Icons.assignment,
      label: 'Compliance & Documents',
      route: '/compliance',
    ),
    SidebarItem(
      icon: Icons.hub,
      label: 'Hub Performance',
      route: '/hub-performance',
    ),
    SidebarItem(
      icon: Icons.settings,
      label: 'Settings',
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = _isCollapsed ? 80.0 : 280.0;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo/Header
          Container(
            padding: EdgeInsets.all(_isCollapsed ? 16 : 24),
            child: _isCollapsed
                ? Icon(
                    Icons.local_car_wash,
                    size: 32,
                    color: AppColors.primary,
                  )
                : Row(
                    children: [
                      Icon(
                        Icons.local_car_wash,
                        size: 32,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'GoGreen',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
          ),
          const Divider(height: 1),
          
          // Navigation Items
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isActive = widget.currentRoute == item.route ||
                    widget.currentRoute.startsWith(item.route);

                return _SidebarItemWidget(
                  item: item,
                  isActive: isActive,
                  isCollapsed: _isCollapsed,
                  onTap: () {
                    context.go(item.route);
                  },
                );
              },
            ),
          ),
          
          // Theme Toggle & Collapse
          if (!widget.isCollapsed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return IconButton(
                        icon: Icon(
                          themeProvider.themeMode == ThemeMode.dark
                              ? Icons.light_mode
                              : Icons.dark_mode,
                        ),
                        onPressed: () {
                          themeProvider.toggleTheme();
                        },
                        tooltip: themeProvider.themeMode == ThemeMode.dark
                            ? 'Light Mode'
                            : 'Dark Mode',
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(_isCollapsed ? Icons.chevron_right : Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _isCollapsed = !_isCollapsed;
                      });
                    },
                    tooltip: _isCollapsed ? 'Expand' : 'Collapse',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final String label;
  final String route;

  SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class _SidebarItemWidget extends StatelessWidget {
  final SidebarItem item;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItemWidget({
    required this.item,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.all(isCollapsed ? 16 : 16),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(color: AppColors.primary.withOpacity(0.3))
                  : null,
            ),
            child: isCollapsed
                ? Icon(
                    item.icon,
                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                  )
                : Row(
                    children: [
                      Icon(
                        item.icon,
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
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

