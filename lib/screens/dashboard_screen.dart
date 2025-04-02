import 'package:flutter/material.dart';
import 'package:hydrometrie_dashboard/screens/station_details_screen.dart';
import 'package:hydrometrie_dashboard/screens/stat_cards_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              StationDetailsScreen(),
              SizedBox(width: 24),
              StatCardsScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
