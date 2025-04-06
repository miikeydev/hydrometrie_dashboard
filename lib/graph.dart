import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HydroLineChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Pour éviter les erreurs quand il n'y a pas de données
    final bool hasData = dates.isNotEmpty && values.isNotEmpty && dates.length == values.length;

    // Créer un format pour l'affichage des dates
    final dateFormat = DateFormat('dd/MM HH:mm');
    
    // Couleurs différentes selon le type de graphique
    final Color mainColor = isHeightChart 
        ? Color(0xFF64B5F6) // Bleu plus clair pour hauteur
        : Color(0xFF1976D2); // Bleu plus foncé pour débit
    
    final Color gradientColor = isHeightChart
        ? Color(0xFFBBDEFB).withOpacity(0.5) // Très clair pour hauteur
        : Color(0xFF2196F3).withOpacity(0.5); // Moyennement clair pour débit

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
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: hasData ? LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: false, // Suppression de la grille
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        // Affiche seulement quelques dates clés pour éviter la surcharge
                        if (hasData && value.toInt() >= 0 && value.toInt() < dates.length) {
                          final step = (dates.length / 5).ceil(); // Max 5 valeurs
                          if (value.toInt() % step == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                dateFormat.format(dates[value.toInt()]),
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
                        // Affiche uniquement un nombre limité de valeurs
                        final step = _calculateStep(values, 4); // Max 4 valeurs
                        if (value % step == 0) {
                          return Text(
                            _formatValue(value),
                            style: const TextStyle(fontSize: 10),
                          );
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
                  border: Border.all(color: Colors.grey.shade300),
                ),
                minX: 0,
                maxX: hasData ? (dates.length - 1).toDouble() : 10,
                minY: hasData ? _getMinY(values) : 0,
                maxY: hasData ? _getMaxY(values) : 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: hasData
                        ? List.generate(dates.length, (index) {
                            return FlSpot(index.toDouble(), values[index]);
                          })
                        : [const FlSpot(0, 0), const FlSpot(1, 1)],
                    isCurved: true,
                    color: mainColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: false,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      // Un dégradé du bleu vers transparent
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
                    getTooltipColor: (_) => mainColor.withOpacity(0.8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final int index = spot.x.toInt();
                        if (hasData && index >= 0 && index < dates.length) {
                          final DateTime date = dates[index];
                          final double value = values[index];
                          return LineTooltipItem(
                            '${dateFormat.format(date)}\n${_formatValueWithUnit(value, isHeightChart)}',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } else {
                          return const LineTooltipItem('', TextStyle());
                        }
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
              ),
            ) : Center(
              child: Text(
                'Aucune donnée disponible',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMinY(List<double> values) {
    if (values.isEmpty) return 0;
    // Trouver le minimum des valeurs et ajouter une marge pour l'esthétique
    double min = values.reduce((a, b) => a < b ? a : b);
    return min > 0 ? min * 0.9 : min * 1.1; // Inclut les valeurs négatives
  }

  double _getMaxY(List<double> values) {
    if (values.isEmpty) return 10;
    // Trouver le maximum des valeurs et ajouter une marge pour l'esthétique
    double max = values.reduce((a, b) => a > b ? a : b);
    return max > 0 ? max * 1.1 : max * 0.9; // Inclut les valeurs négatives
  }
  
  double _calculateStep(List<double> values, int maxSteps) {
    if (values.isEmpty) return 1.0;
    double min = values.reduce((a, b) => a < b ? a : b);
    double max = values.reduce((a, b) => a > b ? a : b);
    double range = max - min;

    if (range <= 0) return 1.0;
    return (range / maxSteps).ceilToDouble();
  }

  // Formater les valeurs pour les afficher de façon plus lisible (K, M, etc.)
  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed((value % 1000000 == 0) ? 0 : 1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed((value % 1000 == 0) ? 0 : 1)}k';
    } else if (value % 1 == 0) {
      return value.toStringAsFixed(0); // Affiche uniquement la partie entière
    } else {
      return value.toStringAsFixed(2);
    }
  }
  
  // Formater les valeurs avec l'unité appropriée
  String _formatValueWithUnit(double value, bool isHeight) {
    String formattedValue = _formatValue(value);
    String unit = isHeight ? 'm' : 'm³/s';
    return '$formattedValue $unit';
  }
}