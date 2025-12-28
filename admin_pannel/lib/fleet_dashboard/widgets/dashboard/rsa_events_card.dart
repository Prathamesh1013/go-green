import 'package:flutter/material.dart';
import '../../models/rsa_event.dart';
import '../../theme/app_colors.dart';

class RSAEventsCard extends StatelessWidget {
  final List<RSAEvent> events;

  const RSAEventsCard({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FleetColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Road Safety Events (RSA)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: FleetColors.gray900),
          ),
          const SizedBox(height: 16),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No events recorded', style: TextStyle(color: FleetColors.gray500))),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(2),
              },
              children: [
                const TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('EVENT TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FleetColors.gray500)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('SEVERITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FleetColors.gray500)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FleetColors.gray500)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('LOCATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FleetColors.gray500)),
                    ),
                  ],
                ),
                ...events.map((event) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: FleetColors.orange100, borderRadius: BorderRadius.circular(4)),
                            child: const Icon(Icons.warning_amber, size: 14, color: FleetColors.orange600),
                          ),
                          const SizedBox(width: 8),
                          Text(event.type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: FleetColors.gray900)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(event.severity).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.severity,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _getSeverityColor(event.severity)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(event.time, style: const TextStyle(fontSize: 13, color: FleetColors.gray600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: FleetColors.purple600),
                          const SizedBox(width: 6),
                          Expanded(child: Text(event.location, style: const TextStyle(fontSize: 13, color: FleetColors.gray600), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ],
                )),
              ],
            ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low': return FleetColors.green600;
      case 'medium': return FleetColors.orange600;
      case 'high': return FleetColors.red600;
      default: return FleetColors.gray600;
    }
  }
}
