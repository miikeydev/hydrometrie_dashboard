import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'station.dart';
import 'providers.dart';
import 'gaugeChart.dart' as gauge;
import 'statBox.dart' as statbox;
import 'graph.dart' as graph;
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final observationsAsync = ref.watch(observationsProvider);
    final selectedStation = ref.watch(selectedStationProvider);
    final dateRange = ref.watch(dateRangeProvider);

    List<DateTime> xValuesDebitDates = [];
    List<double> yValuesDebit = [];
    List<DateTime> xValuesHauteurDates = [];
    List<double> yValuesHauteur = [];

    double debitMoyen = 0.0;
    double hauteurMoyenne = 0.0;
    String minDebit = "N/A";
    String maxDebit = "N/A";
    String minHauteur = "N/A";
    String maxHauteur = "N/A";

    String dashboardTitle = "Hydrométrie Dashboard";
    if (selectedStation != null) {
      final stationName = selectedStation['libelle_station'] ?? "";
      if (stationName.isNotEmpty) {
        dashboardTitle += " - $stationName";
      }
    }

    if (observationsAsync.whenData((data) => data).valueOrNull != null) {
      final allData = observationsAsync.value!;

      final debitData = allData.where((obs) => obs['grandeur_hydro'] == 'Q').toList();
      final hauteurData = allData.where((obs) => obs['grandeur_hydro'] == 'H').toList();

      developer.log('Données de débit: ${debitData.length} observations', name: 'dashboard');
      developer.log('Données de hauteur: ${hauteurData.length} observations', name: 'dashboard');

      if (debitData.isNotEmpty) {
        debitData.sort((a, b) => DateTime.parse(a['date_obs']).compareTo(DateTime.parse(b['date_obs'])));
        xValuesDebitDates = debitData.map<DateTime>((obs) => DateTime.parse(obs['date_obs'])).toList();
        yValuesDebit = debitData.map<double>((obs) {
          return (obs['resultat_obs'] is num) ? obs['resultat_obs'].toDouble() : 0.0;
        }).toList();

        final debitValues = yValuesDebit.where((value) => !value.isNaN && value >= 0).toList();
        if (debitValues.isNotEmpty) {
          debitMoyen = debitValues.reduce((a, b) => a + b) / debitValues.length;
          final minDebitValue = debitValues.reduce((a, b) => a < b ? a : b);
          final maxDebitValue = debitValues.reduce((a, b) => a > b ? a : b);
          minDebit = formatValue(minDebitValue, 'm³/s');
          maxDebit = formatValue(maxDebitValue, 'm³/s');
        }
      }

      if (hauteurData.isNotEmpty) {
        hauteurData.sort((a, b) => DateTime.parse(a['date_obs']).compareTo(DateTime.parse(b['date_obs'])));
        xValuesHauteurDates = hauteurData.map<DateTime>((obs) => DateTime.parse(obs['date_obs'])).toList();
        yValuesHauteur = hauteurData.map<double>((obs) {
          return (obs['resultat_obs'] is num) ? obs['resultat_obs'].toDouble() : 0.0;
        }).toList();

        final hauteurValues = yValuesHauteur.where((value) => !value.isNaN && value >= 0).toList();
        if (hauteurValues.isNotEmpty) {
          hauteurMoyenne = hauteurValues.reduce((a, b) => a + b) / hauteurValues.length;
          final minHauteurValue = hauteurValues.reduce((a, b) => a < b ? a : b);
          final maxHauteurValue = hauteurValues.reduce((a, b) => a > b ? a : b);
          minHauteur = formatValue(minHauteurValue, 'm');
          maxHauteur = formatValue(maxHauteurValue, 'm');
        }
      }
    }

    String periodLabel = "";
    if (dateRange != null) {
      final dateFormat = DateFormat('dd/MM/yyyy');
      periodLabel = " (${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)})";
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    dashboardTitle,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 300, 
                    child: StationInfoPanel(
                      initialDateRange: DateTimeRange(
                        start: DateTime.now().subtract(const Duration(days: 5)),
                        end: DateTime.now(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  SizedBox(
                    width: 220,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Expanded(
                                child: gauge.CircleGaugeCard(
                                  value: debitMoyen,
                                  min: 0,
                                  max: debitMoyen * 2 > 0 ? debitMoyen * 2 : 100,
                                  unit: 'm³/s',
                                  label: 'Moyenne du débit',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: gauge.CircleGaugeCard(
                                  value: hauteurMoyenne,
                                  min: 0,
                                  max: hauteurMoyenne * 2 > 0 ? hauteurMoyenne * 2 : 10,
                                  unit: 'm',
                                  label: 'Moyenne de hauteur',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: statbox.StatBox(
                                        label: 'Min Q',
                                        value: minDebit,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: statbox.StatBox(
                                        label: 'Max Q',
                                        value: maxDebit,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: statbox.StatBox(
                                        label: 'Min H',
                                        value: minHauteur,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: statbox.StatBox(
                                        label: 'Max H',
                                        value: maxHauteur,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 1,
                          child: graph.HydroLineChart(
                            title: 'Débit (m³/s)$periodLabel',
                            dates: xValuesDebitDates,
                            values: yValuesDebit,
                            startDate: dateRange.start,
                            endDate: dateRange.end,
                            isHeightChart: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          flex: 1,
                          child: graph.HydroLineChart(
                            title: 'Hauteur (m)$periodLabel',
                            dates: xValuesHauteurDates,
                            values: yValuesHauteur,
                            startDate: dateRange.start,
                            endDate: dateRange.end,
                            isHeightChart: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatValue(double value, String unit) {
    String formattedValue;
    if (value.isNaN || value.isInfinite) {
      return "N/A";
    } else if (value >= 1000000) {
      formattedValue = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      formattedValue = '${(value / 1000).toStringAsFixed(1)}k';
    } else if (value >= 100) {
      formattedValue = value.toStringAsFixed(0);
    } else if (value >= 10) {
      formattedValue = value.toStringAsFixed(1);
    } else {
      formattedValue = value.toStringAsFixed(2);
    }
    return '$formattedValue $unit';
  }
}
