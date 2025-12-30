import 'package:flutter/material.dart';

class HubHeader extends StatelessWidget {
  const HubHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Hub Performance Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          'Last 30 Days',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
