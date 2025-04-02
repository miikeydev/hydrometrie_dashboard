import 'package:flutter/material.dart';
import 'package:hydrometrie_dashboard/screens/dashboard_screen.dart';
import 'package:hydrometrie_dashboard/screens/station_details_screen.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    ),
  );
}
