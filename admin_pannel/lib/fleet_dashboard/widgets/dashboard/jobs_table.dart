import 'package:flutter/material.dart';
import '../ui/custom_card.dart';
import '../../models/job.dart';
import '../../theme/app_colors.dart';

class JobsTable extends StatelessWidget {
  final List<JobCategory> jobs;

  const JobsTable({super.key, required this.jobs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jobs by Category',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 24),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(4),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    children: [
                      _buildHeaderCell('Category', align: TextAlign.left),
                      _buildHeaderCell('Total Jobs'),
                      _buildHeaderCell('Completed'),
                      _buildHeaderCell('Pending'),
                      _buildHeaderCell('SLA Status'),
                    ],
                  ),
                  const TableRow(children: [
                    SizedBox(height: 12), SizedBox(height: 12), SizedBox(height: 12), SizedBox(height: 12), SizedBox(height: 12)
                  ]),
                  ...jobs.map((job) => TableRow(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: FleetColors.border)),
                    ),
                    children: [
                      _buildCell(job.category, align: TextAlign.left, isBold: true),
                      _buildCell(job.total.toString()),
                      _buildCell(job.completed.toString(), color: FleetColors.green600),
                      _buildCell(job.pending.toString(), color: FleetColors.orange600),
                      _buildSLACell(job.slaStatus),
                    ],
                  )),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildSummaryCard(
              icon: Icons.location_on,
              iconColor: FleetColors.red500,
              iconBgColor: FleetColors.red100,
              title: 'Peak Breakdown Zones',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildZoneItem('Zone A (Downtown)'),
                  _buildZoneItem('Zone C (Industrial)'),
                  _buildZoneItem('Zone E (Highway-12)'),
                ],
              ),
            )),
            const SizedBox(width: 24),
            Expanded(child: _buildSummaryCard(
              icon: Icons.access_time,
              iconColor: FleetColors.blue600,
              iconBgColor: FleetColors.blue100,
              title: 'Avg Response Time',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '18 mins',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: FleetColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fleet-wide average',
                    style: TextStyle(
                      fontSize: 12,
                      color: FleetColors.gray500,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(width: 24),
            Expanded(child: _buildSummaryCard(
              icon: Icons.build,
              iconColor: FleetColors.orange600,
              iconBgColor: FleetColors.orange100,
              title: 'Service Due Soon',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '42',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: FleetColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vehicles in next 7 days',
                    style: TextStyle(
                      fontSize: 12,
                      color: FleetColors.gray500,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, {TextAlign align = TextAlign.center}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: FleetColors.gray900,
        ),
      ),
    );
  }

  Widget _buildCell(String text, {
    TextAlign align = TextAlign.center, 
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 14,
          color: color ?? FleetColors.gray900,
          fontWeight: isBold ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSLACell(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case 'on-track':
        bgColor = FleetColors.gray900;
        textColor = Colors.white;
        text = 'On Track';
        break;
      case 'at-risk':
        bgColor = FleetColors.gray100;
        textColor = FleetColors.gray900;
        text = 'At Risk';
        break;
      case 'critical':
        bgColor = FleetColors.red600;
        textColor = Colors.white;
        text = 'Critical';
        break;
      default:
        bgColor = FleetColors.gray100;
        textColor = FleetColors.gray600;
        text = status;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required Widget content,
  }) {
    return CustomCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FleetColors.gray900,
                  ),
                ),
                const SizedBox(height: 8),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: FleetColors.gray600,
        ),
      ),
    );
  }
}
