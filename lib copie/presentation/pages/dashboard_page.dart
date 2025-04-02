import 'package:flutter/material.dart';
import '../widgets/average_gauge.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Hydrometrie')),
      body: Row(
        children: [
          SizedBox(width: 200, child: Center(child: AverageGauge())),
          Expanded(child: Center(child: Text('Placeholder for other content'))),
        ],
      ),
    );
  }
}
