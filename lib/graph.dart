import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'theme.dart';

class HydroLineChart extends StatefulWidget {
  final String title;
  final List<DateTime> dates;
  final List<double> values;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isHeightChart;

  const HydroLineChart({
    Key? key,
    required this.title,
    required this.dates,
    required this.values,
    this.startDate,
    this.endDate,
    this.isHeightChart = false,
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
        ? AppTheme.hauteurMainColor
        : AppTheme.debitMainColor;

    final trend = hasData ? _calculateLinearRegression(widget.values) : {'slope': 0.0, 'intercept': 0.0};
    final double slope = trend['slope']!;
    final double intercept = trend['intercept']!;
    final bool isTrendPositive = slope >= 0;
    final Color trendColor = isTrendPositive ? Colors.green : Colors.red;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getSecondaryContainerColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
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
              color: AppTheme.getTextColor(context),
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
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]!.withOpacity(0.5)
                                : Colors.grey[300]!.withOpacity(0.5),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]!.withOpacity(0.5)
                                : Colors.grey[300]!.withOpacity(0.5),
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
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.getTextColor(context),
                                      ),
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
                                  if ((value - checkValue).abs() < step / 10) {
                                    return Text(
                                      _formatValue(value),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.getTextColor(context),
                                      ),
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
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]!.withOpacity(0.5)
                                : Colors.grey[300]!.withOpacity(0.5)),
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
                              ? List.generate(widget.dates.length, (index) {
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
                                mainColor.withOpacity(0.5),
                                mainColor.withOpacity(0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        if (hasData)
                          _buildTrendLine(widget.values),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipColor: (touchedSpots) {
                            return isDarkMode
                                ? Colors.grey[800]!.withOpacity(0.9)
                                : Colors.white.withOpacity(0.9);
                          },
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            if (touchedSpots.isEmpty) {
                              return [];
                            }

                            final int index = touchedSpots.first.x.toInt();

                            if (index >= 0 && index < widget.dates.length) {
                              final DateTime date = widget.dates[index];
                              final double actualValue = widget.values[index];
                              final double trendValue = slope * index + intercept;

                              final LineTooltipItem actualValueItem = LineTooltipItem(
                                '${DateFormat('dd/MM HH:mm').format(date)}\n'
                                '${_formatValueWithUnit(actualValue, widget.isHeightChart)}',
                                TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              );

                              final LineTooltipItem trendValueItem = LineTooltipItem(
                                'Tendance: ${_formatValueWithUnit(trendValue, widget.isHeightChart)} '
                                '(${isTrendPositive ? '▲' : '▼'})',
                                TextStyle(
                                  color: trendColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );

                              return [actualValueItem, trendValueItem];
                            } else {
                              return [];
                            }
                          },
                        ),
                        getTouchedSpotIndicator: (barData, spotIndexes) {
                          return spotIndexes.map((index) {
                            final List<LineChartBarData> allBars = [
                              LineChartBarData(
                                spots: hasData
                                    ? List.generate(widget.dates.length, (index) {
                                        return FlSpot(index.toDouble(), widget.values[index]);
                                      })
                                    : [const FlSpot(0, 0), const FlSpot(1, 1)],
                                color: mainColor,
                              ),
                              if (hasData) _buildTrendLine(widget.values),
                            ];
                            
                            final currentBar = allBars.firstWhere((bar) => bar == barData, orElse: () => allBars[0]);
                            final isMainLine = currentBar == allBars[0];
                            
                            return TouchedSpotIndicatorData(
                              FlLine(
                                color: isMainLine 
                                    ? mainColor 
                                    : currentBar.color ?? Colors.transparent,
                                strokeWidth: 2,
                                dashArray: isMainLine ? null : [5, 5],
                              ),
                              FlDotData(
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: isMainLine ? 5 : 4,
                                    color: isMainLine 
                                        ? mainColor 
                                        : barData.color ?? Colors.transparent,
                                    strokeWidth: 2,
                                    strokeColor: isDarkMode ? Colors.black : Colors.white,
                                  );
                                },
                              ),
                            );
                          }).toList();
                        },
                        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                        },
                        handleBuiltInTouches: true,
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      "En attente des données...",
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
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

  LineChartBarData _buildTrendLine(List<double> values) {
    final trend = _calculateLinearRegression(values);
    final double slope = trend['slope']!;
    final double intercept = trend['intercept']!;

    final List<FlSpot> trendSpots = List.generate(values.length, (index) {
      final double y = slope * index + intercept;
      return FlSpot(index.toDouble(), y);
    });

    final Color trendColor = slope >= 0
        ? Colors.green.withOpacity(0.6)
        : Colors.red.withOpacity(0.6);

    return LineChartBarData(
      spots: trendSpots,
      isCurved: false,
      color: trendColor,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      dashArray: [5, 5],
    );
  }

  Map<String, double> _calculateLinearRegression(List<double> values) {
    if (values.length < 2) return {'slope': 0.0, 'intercept': values.isNotEmpty ? values.first : 0.0};
    final int n = values.length;
    final List<double> x = List.generate(n, (index) => index.toDouble());
    final double sumX = x.reduce((a, b) => a + b);
    final double sumY = values.reduce((a, b) => a + b);
    final double sumXY = List.generate(n, (index) => x[index] * values[index])
        .reduce((a, b) => a + b);
    final double sumX2 = x.map((xi) => xi * xi).reduce((a, b) => a + b);

    final denominator = (n * sumX2 - sumX * sumX);
    if (denominator == 0) return {'slope': 0.0, 'intercept': sumY / n};

    final double slope = (n * sumXY - sumX * sumY) / denominator;
    final double intercept = (sumY - slope * sumX) / n;

    return {'slope': slope, 'intercept': intercept};
  }

  double _getMinY(List<double> values) {
    if (values.isEmpty) return 0;
    double min = values.reduce((a, b) => a < b ? a : b);
    final trend = _calculateLinearRegression(values);
    final trendMin = trend['intercept']!;
    final trendMax = trend['slope']! * (values.length - 1) + trend['intercept']!;
    min = [min, trendMin, trendMax].reduce((a, b) => a < b ? a : b);
    return min > 0 ? min * 0.9 : min * 1.1;
  }

  double _getMaxY(List<double> values) {
    if (values.isEmpty) return 10;
    double max = values.reduce((a, b) => a > b ? a : b);
    final trend = _calculateLinearRegression(values);
    final trendMin = trend['intercept']!;
    final trendMax = trend['slope']! * (values.length - 1) + trend['intercept']!;
    max = [max, trendMin, trendMax].reduce((a, b) => a > b ? a : b);
    return max > 0 ? max * 1.1 : max * 0.9;
  }

  String _formatValue(double value) {
    if (value.isNaN || value.isInfinite) return "N/A";
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
    if (formattedValue == "N/A") return "N/A";
    String unit = isHeight ? 'mm' : 'm³/s';
    return '$formattedValue $unit';
  }
}