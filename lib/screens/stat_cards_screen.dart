import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class StatCardsScreen extends StatelessWidget {
  const StatCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            StatCard(
              icon: Icons.flash_on,
              title: 'Débit',
              value: '300L/min',
              min: '200L/min',
              max: '400L/min',
              percent: 0.10,
              percentLabel: '+10%',
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFB9ECF9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            SizedBox(height: 20),
            StatCard(
              icon: Icons.waves,
              title: 'Hauteur',
              value: '20m',
              min: '10m',
              max: '30m',
              percent: 0.08,
              percentLabel: '+8%',
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFB8EBF7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            SizedBox(height: 20),
            StatCard(
              icon: Icons.cloud,
              title: 'Pluie',
              value: '200mm',
              min: '100mm',
              max: '300mm',
              percent: 0.42,
              percentLabel: '+42%',
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFB8C7F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String min;
  final String max;
  final double percent;
  final String percentLabel;
  final Gradient gradient;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.percent,
    required this.percentLabel,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 330, maxWidth: 330),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(4, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: CircularPercentIndicator(
              radius: 28,
              lineWidth: 5,
              percent: percent.clamp(0.0, 1.0),
              center: Text(
                percentLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              progressColor: Colors.blueAccent,
              backgroundColor: Colors.grey.shade200,
              circularStrokeCap: CircularStrokeCap.round,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Max: $max   Min: $min',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
