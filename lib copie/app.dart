import 'package:flutter/material.dart';
import 'presentation/pages/dashboard_page.dart';
import 'screens/stat_cards_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydrometrie Dashboard',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardPage(),
        '/stats': (context) => const StatCardsScreen(),
      },
    );
  }
}
