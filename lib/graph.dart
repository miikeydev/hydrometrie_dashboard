import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// A simple reusable line chart widget (using the fl_chart package).
///
/// [title] - The chart title (e.g., 'Hauteur (H)').
/// [xValues] and [yValues] - Parallel lists representing X and Y coordinates.
///   They must have the same length.
/// The chart automatically infers [minY], [maxY] (and [minX], [maxX]) from the data,
///   but you can override them if desired.
class HydroLineChart extends StatelessWidget {
  final String title;
  final List<double> xValues; // e.g. [0, 1, 2, 3] or time in hours
  final List<double> yValues; // e.g. [10, 25, 40, 93]
  final double? minY;
  final double? maxY;
  final double? minX;
  final double? maxX;

  const HydroLineChart({
    Key? key,
    required this.title,
    required this.xValues,
    required this.yValues,
    this.minY,
    this.maxY,
    this.minX,
    this.maxX,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert incoming xValues,yValues -> list of FlSpot
    final spots = <FlSpot>[];
    for (int i = 0; i < xValues.length; i++) {
      spots.add(FlSpot(xValues[i], yValues[i]));
    }

    // If user hasn't provided min/max, derive them from the data
    final derivedMinX = xValues.isNotEmpty ? (minX ?? xValues.reduce((a, b) => a < b ? a : b)) : 0.0;
    final derivedMaxX = xValues.isNotEmpty ? (maxX ?? xValues.reduce((a, b) => a > b ? a : b)) : 1.0;
    final derivedMinY = yValues.isNotEmpty ? (minY ?? yValues.reduce((a, b) => a < b ? a : b)) : 0.0;
    final derivedMaxY = yValues.isNotEmpty ? (maxY ?? yValues.reduce((a, b) => a > b ? a : b)) : 1.0;


    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: derivedMinX,
                maxX: derivedMaxX,
                minY: derivedMinY,
                maxY: derivedMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                  getDrawingVerticalLine: (value) =>
                      FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (derivedMaxX - derivedMinX) / 4,
                      getTitlesWidget: (value, meta) {
                        // Example: convert 'value' to an hour label or just show the numeric
                        return Text(
                          _formatX(value),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (derivedMaxY - derivedMinY) / 4,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineTouchData: LineTouchData(enabled: true),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    // Couleur du trait
                    gradient: LinearGradient(
                      colors: [Colors.blue.withAlpha((0.9 * 255).toInt()), Colors.lightBlue],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      // Dégradé sous la ligne
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withAlpha((0.5 * 255).toInt()),
                          Colors.blue.withAlpha((0.0 * 255).toInt()),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Example method for formatting X values (like hours). Customize as needed.
  String _formatX(double x) {
    // For example, treat x as "hours" in the day:
    final int hour = x.round();
    final minutes = ((x - hour) * 60).round();
    final hh = hour.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}