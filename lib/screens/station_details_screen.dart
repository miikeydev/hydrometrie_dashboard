import 'package:flutter/material.dart';
import 'package:hydrometrie_dashboard/screens/stat_cards_screen.dart';

class StationDetailsScreen extends StatefulWidget {
  const StationDetailsScreen({super.key});

  @override
  State<StationDetailsScreen> createState() => _StationDetailsScreenState();
}

class _StationDetailsScreenState extends State<StationDetailsScreen> {
  DateTime? startDate;
  DateTime? endDate;

  Future<void> pickDate({required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  String getDateRangeText() {
    if (startDate == null || endDate == null) {
      return "Aucune date sélectionnée";
    }

    final start = startDate!.toLocal().toIso8601String().substring(0, 10);
    final end = endDate!.toLocal().toIso8601String().substring(0, 10);
    return "$start à $end";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de recherche
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher ou entrer un code station',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Infos station
          const Text(
            'Code station',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text('V350401201'),
          const SizedBox(height: 12),

          const Text('Adresse', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '745.0',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' Mesurée\nNon qualifiée\nBrute'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Coordonnées',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text('45.235°N  4.633E'),

          const Divider(height: 32),

          // Sélection de dates
          const Text(
            'Plage de dates',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ElevatedButton(
            onPressed: () => pickDate(isStart: true),
            child: const Text("Sélectionner date de début"),
          ),
          const SizedBox(height: 8),

          ElevatedButton(
            onPressed: () => pickDate(isStart: false),
            child: const Text("Sélectionner date de fin"),
          ),
          const SizedBox(height: 12),

          Text(getDateRangeText()),
        ],
      ),
    );
  }
}

class StatCardsHomePage extends StatelessWidget {
  const StatCardsHomePage({super.key});

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
