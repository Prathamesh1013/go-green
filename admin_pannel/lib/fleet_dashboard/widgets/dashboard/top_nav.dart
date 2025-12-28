import 'package:flutter/material.dart';
import '../ui/custom_input.dart';
import '../ui/custom_button.dart';
import '../ui/custom_avatar.dart';
import '../../theme/app_colors.dart';

class TopNav extends StatelessWidget {
  const TopNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FleetColors.background,
        border: Border(
          bottom: BorderSide(color: FleetColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [FleetColors.blue600, FleetColors.blue700],
              ),
            ),
            child: const Center(
              child: Text(
                'EV',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FleetOps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: FleetColors.gray900,
                ),
              ),
              Text(
                'EV Fleet Management',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: FleetColors.gray500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Center - Search & Date Range
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: CustomInput(
                      placeholder: 'Search Vehicle ID / Job ID...',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.search, size: 16, color: FleetColors.gray400),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                CustomButton(
                  variant: ButtonVariant.outline,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  text: 'Last 30 Days',
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Right - Notifications & Profile
          Row(
            children: [
              CustomButton(
                variant: ButtonVariant.ghost,
                size: ButtonSize.icon,
                onPressed: () {},
                child: Stack(
                  children: [
                    const Icon(Icons.notifications, size: 20),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: FleetColors.red500,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const CustomAvatar(
                child: Icon(Icons.person, size: 16, color: FleetColors.gray600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
