import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

/// A simple reusable widget that displays:
/// - A circular "gauge" (donut) indicating [value] in relation to [min] and [max].
/// - The numeric [value] at the center, plus the [unit].
/// - A descriptive [label] on the right side.
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

  @override
  Widget build(BuildContext context) {
    // Compute the fraction for the circular indicator (clamped between 0 and 1).
    final fraction = (value - min) / (max - min);
    final safeFraction = fraction.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular "donut" indicator (using the percent_indicator package).
          CircularPercentIndicator(
            radius: 44,
            lineWidth: 8,
            percent: safeFraction,
            progressColor: Colors.blue,
            backgroundColor: Colors.grey[200]!,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Descriptive label
          Expanded(
            child: Text(
              label,
            ),
          ),
        ],
      ),
    );
  }
}
