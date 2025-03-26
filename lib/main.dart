import 'package:flutter/material.dart';
import 'package:hydrometrie_dashboard/app.dart';
import 'screens/stat_cards_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StatCardsScreen(),
    );
  }
}
