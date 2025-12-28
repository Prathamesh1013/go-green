import 'package:flutter/material.dart';

class HubComparisonTable extends StatelessWidget {
  const HubComparisonTable({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
        dataTextStyle: Theme.of(context).textTheme.bodyMedium,
        columns: const [
          DataColumn(label: Text('Hub')),
          DataColumn(label: Text('Vehicles')),
          DataColumn(label: Text('Healthy %')),
          DataColumn(label: Text('Downtime (hrs)')),
        ],
        rows: const [
          DataRow(cells: [
            DataCell(Text('Nashik')),
            DataCell(Text('90')),
            DataCell(Text('78%')),
            DataCell(Text('0.8')),
          ]),
          DataRow(cells: [
            DataCell(Text('Pune')),
            DataCell(Text('100')),
            DataCell(Text('82%')),
            DataCell(Text('1.2')),
          ]),
          DataRow(cells: [
            DataCell(Text('Mumbai')),
            DataCell(Text('75')),
            DataCell(Text('71%')),
            DataCell(Text('1.8')),
          ]),
        ],
      ),
    );
  }
}
