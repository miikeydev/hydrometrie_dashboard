import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class StatCardsScreen extends StatelessWidget {
  const StatCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Column(
                children: [
                  HorizontalCircularStatCard(
                    value: '136',
                    unit: 'm³/s',
                    label: 'Moyenne du débit',
                    percent: 0.85,
                  ),
                  SizedBox(height: 20),
                  HorizontalCircularStatCard(
                    value: '2.57',
                    unit: 'm',
                    label: 'Moyenne de hauteur',
                    percent: 0.6,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RectStatCard(title: 'Min débit', value: '78', unit: 'm/s'),
                  SizedBox(width: 16),
                  RectStatCard(title: 'Max débit', value: '165', unit: 'm/s'),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RectStatCard(title: 'Min hauteur', value: '1,99', unit: 'm'),
                  SizedBox(width: 16),
                  RectStatCard(title: 'Max hauteur', value: '3,10', unit: 'm'),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class HorizontalCircularStatCard extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final double percent;

  const HorizontalCircularStatCard({
    super.key,
    required this.value,
    required this.unit,
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320, // légèrement réduit pour mieux tenir sur petit écran
      height: 180,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 50,
            lineWidth: 10,
            percent: percent,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(unit, style: const TextStyle(fontSize: 12)),
              ],
            ),
            progressColor: Colors.blue,
            backgroundColor: Colors.grey.shade300,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}

class RectStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;

  const RectStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
