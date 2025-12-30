import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gogreen_admin/widgets/responsive_layout.dart';
import 'package:gogreen_admin/widgets/glass_card.dart';
import 'package:gogreen_admin/widgets/hub_header.dart';
import 'package:gogreen_admin/widgets/hub_health_cards.dart';
import 'package:gogreen_admin/widgets/hub_comparison_table.dart';
import 'package:gogreen_admin/providers/theme_provider.dart';

class HubPerformancePage extends StatelessWidget {
  const HubPerformancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      currentRoute: '/hub-performance',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hub Performance'),
          actions: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return IconButton(
                  icon: Icon(
                    themeProvider.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () => themeProvider.toggleTheme(),
                  tooltip: themeProvider.themeMode == ThemeMode.dark
                      ? 'Switch to Light Mode'
                      : 'Switch to Dark Mode',
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HubHeader(),
              const SizedBox(height: 20),
              const HubHealthCards(),
              const SizedBox(height: 20),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hub Comparison',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const HubComparisonTable(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
