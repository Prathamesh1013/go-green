import 'package:flutter/material.dart';
import 'package:gogreen_admin/widgets/sidebar.dart';
import 'package:gogreen_admin/widgets/bottom_nav.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const ResponsiveLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile: Bottom navigation
          return Scaffold(
            body: child,
            bottomNavigationBar: BottomNav(currentRoute: currentRoute),
          );
        } else if (constraints.maxWidth < 1024) {
          // Tablet: Collapsible sidebar
          return Scaffold(
            body: Row(
              children: [
                Sidebar(
                  currentRoute: currentRoute,
                  isCollapsed: true,
                ),
                Expanded(child: child),
              ],
            ),
          );
        } else {
          // Desktop: Full sidebar
          return Scaffold(
            body: Row(
              children: [
                Sidebar(
                  currentRoute: currentRoute,
                  isCollapsed: false,
                ),
                Expanded(child: child),
              ],
            ),
          );
        }
      },
    );
  }
}
