import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

/// A simple reusable widget that displays:
/// - A circular "gauge" (donut) indicating [value] in relation to [min] and [max].
/// - The numeric [value] at the center, plus the [unit].
/// - A descriptive [label] on the top side.
///
/// Customize [value], [min], [max], [unit], and [label] easily
/// by passing them as constructor parameters.
class CircleGaugeCard extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String unit;
  final String label;

  const CircleGaugeCard({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.label,
  }) : super(key: key);

  // Format values for better readability (K, M, etc.)
  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else if (value >= 100) {
      return value.toStringAsFixed(0);
    } else if (value >= 10) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compute the fraction for the circular indicator (clamped between 0 and 1).
    final double percent = max > min ? ((value - min) / (max - min)).clamp(0.0, 1.0) : 0.0;

    // Format the value for display
    final String formattedValue = _formatValue(value);

    return Container(
      padding: const EdgeInsets.all(12), // Réduction du padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gauge title
          Text(
            label,
            style: TextStyle(
              fontSize: 12, // Texte plus petit
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8), // Espacement réduit
          // Circular gauge
          Expanded(
            child: Center(
              child: CircularPercentIndicator(
                radius: 50, // Rayon réduit
                lineWidth: 10.0, // Épaisseur de ligne réduite
                percent: percent,
                center: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Main value
                    Text(
                      formattedValue,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, // Taille de police réduite
                      ),
                    ),

                    // Unit displayed below
                    Positioned(
                      bottom: 32, // Position ajustée
                      child: Text(
                        unit,
                        style: TextStyle(
                          fontSize: 10, // Taille réduite
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                progressColor: _getProgressColor(percent),
                backgroundColor: Colors.grey[200]!,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 800, // Animation plus rapide
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gauge color changes based on the value
  Color _getProgressColor(double percent) {
    if (percent < 0.4) {
      return Colors.blue[300]!; // Light blue for low values
    } else if (percent < 0.7) {
      return Colors.blue; // Standard blue for medium values
    } else {
      return Colors.blue[800]!; // Dark blue for high values
    }
  }
}