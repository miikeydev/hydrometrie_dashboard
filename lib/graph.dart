import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HydroLineChart extends StatefulWidget {
  final String title;
  final List<DateTime> dates;
  final List<double> values;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isHeightChart; // Pour distinguer les graphiques de hauteur et de débit

  const HydroLineChart({
    Key? key,
    required this.title,
    required this.dates,
    required this.values,
    this.startDate,
    this.endDate,
    this.isHeightChart = false, // Par défaut c'est un graphique de débit
  }) : super(key: key);

  @override
  _HydroLineChartState createState() => _HydroLineChartState();
}

class _HydroLineChartState extends State<HydroLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasData = widget.dates.isNotEmpty &&
        widget.values.isNotEmpty &&
        widget.dates.length == widget.values.length;

    final Color mainColor = widget.isHeightChart
        ? const Color(0xFF64B5F6) // Bleu plus clair pour hauteur
        : const Color(0xFF1976D2); // Bleu plus foncé pour débit;

    final Color gradientColor = widget.isHeightChart
        ? const Color(0xFFBBDEFB).withOpacity(0.5) // Très clair pour hauteur
        : const Color(0xFF2196F3).withOpacity(0.5); // Moyennement clair pour débit

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isHeightChart ? "Évolution Hauteur d'eau" : "Évolution Débit",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: hasData
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        drawHorizontalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade300.withOpacity(0.5),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade300.withOpacity(0.5),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (hasData &&
                                  value.toInt() >= 0 &&
                                  value.toInt() < widget.dates.length) {
                                final step =
                                    (widget.dates.length / 5).ceil();
                                if (value.toInt() % step == 0) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(top: 10.0),
                                    child: Text(
                                      DateFormat('dd/MM HH:mm').format(
                                          widget.dates[value.toInt()]),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              if (hasData) {
                                final minY = _getMinY(widget.values);
                                final maxY = _getMaxY(widget.values);
                                final range = maxY - minY;
                                final step = range / 4;

                                for (int i = 0; i <= 4; i++) {
                                  final checkValue = minY + i * step;
                                  if ((value - checkValue).abs() <
                                      step / 10) {
                                    return Text(
                                      _formatValue(value),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                }
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                            color: Colors.grey.shade300.withOpacity(0.5)),
                      ),
                      minX: 0,
                      maxX: hasData
                          ? (widget.dates.length - 1).toDouble()
                          : 10,
                      minY: hasData ? _getMinY(widget.values) : 0,
                      maxY: hasData ? _getMaxY(widget.values) : 10,
                      lineBarsData: [
                        LineChartBarData(
                          spots: hasData
                              ? List.generate(widget.dates.length,
                                  (index) {
                                  return FlSpot(index.toDouble(),
                                      widget.values[index]);
                                })
                              : [
                                  const FlSpot(0, 0),
                                  const FlSpot(1, 1)
                                ],
                          isCurved: true,
                          color: mainColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(
                            show: false,
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                gradientColor,
                                gradientColor.withOpacity(0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipColor: (_) =>
                              mainColor.withOpacity(0.8),
                          getTooltipItems:
                              (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              final int index = spot.x.toInt();
                              if (hasData &&
                                  index >= 0 &&
                                  index < widget.dates.length) {
                                final DateTime date =
                                    widget.dates[index];
                                final double value =
                                    widget.values[index];
                                return LineTooltipItem(
                                  '${DateFormat('dd/MM HH:mm').format(date)}\n${_formatValueWithUnit(value, widget.isHeightChart)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              } else {
                                return const LineTooltipItem(
                                    '', TextStyle());
                              }
                            }).toList();
                          },
                        ),
                        handleBuiltInTouches: true,
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      "En attente des données...", // Message simple
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _getMinY(List<double> values) {
    if (values.isEmpty) return 0;
    double min = values.reduce((a, b) => a < b ? a : b);
    return min > 0 ? min * 0.9 : min * 1.1;
  }

  double _getMaxY(List<double> values) {
    if (values.isEmpty) return 10;
    double max = values.reduce((a, b) => a > b ? a : b);
    return max > 0 ? max * 1.1 : max * 0.9;
  }

  double _calculateInterval(List<double> values) {
    if (values.isEmpty) return 1.0;
    double min = values.reduce((a, b) => a < b ? a : b);
    double max = values.reduce((a, b) => a > b ? a : b);
    double range = max - min;

    if (range <= 0) return 1.0;
    return range / 5;
  }

  double _calculateStep(List<double> values, int maxSteps) {
    if (values.isEmpty) return 1.0;
    double min = values.reduce((a, b) => a < b ? a : b);
    double max = values.reduce((a, b) => a > b ? a : b);
    double range = max - min;

    if (range <= 0) return 1.0;
    return (range / maxSteps).ceilToDouble();
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed((value % 1000000 == 0) ? 0 : 1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed((value % 1000 == 0) ? 0 : 1)}k';
    } else if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  String _formatValueWithUnit(double value, bool isHeight) {
    String formattedValue = _formatValue(value);
    String unit = isHeight ? 'm' : 'm³/s';
    return '$formattedValue $unit';
  }

  String _getNoDataText() {
    final now = DateTime.now().second;
    if (now % 3 == 0) return "-";
    if (now % 3 == 1) return "- -";
    return "- - -";
  }
}