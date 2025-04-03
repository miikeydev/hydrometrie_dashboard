import 'package:flutter/material.dart';
import 'station.dart';      // <-- notre StationInfoPanel épuré
import 'gaugeChart.dart';
import 'statBox.dart';
import 'graph.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
          ),
          child: Container(
            padding:
                const EdgeInsets.only(left: 32, right: 32, bottom: 32, top: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Hydrométrie Dashboard",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      // Barre de filtre (StationInfoPanel épuré)
                      Container(
                        width: 270,
                        child: Center(
                          child: StationInfoPanel(
                            initialDateRange: DateTimeRange(
                              start: DateTime.now().subtract(const Duration(days: 5)),
                              end: DateTime.now(),
                            ),
                            stationSuggestions: const [
                              'Station A',
                              'Station B',
                              'Station C',
                            ],
                            onSearchSelected: (value) {
                              // Faire quelque chose avec la station sélectionnée
                            },
                            onDateRangeChanged: (dateRange) {
                              // Faire quelque chose avec la plage de dates sélectionnée
                            },
                          ),
                        ),
                      ),

                      SizedBox(width: 32),

                      // Colonne Gauche : Gauges circulaires
                      Container(
                        width: 250,
                        child: Column(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: CircleGaugeCard(
                                      value: 136,
                                      min: 0,
                                      max: 200,
                                      unit: 'm³/s',
                                      label: 'Moyenne du débit',
                                    ),
                                  ),
                                  SizedBox(height: 32),
                                  Expanded(
                                    child: CircleGaugeCard(
                                      value: 2.57,
                                      min: 0,
                                      max: 10,
                                      unit: 'm',
                                      label: 'Moyenne de hauteur',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 32),
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: StatBox(
                                            label: 'Min débit',
                                            value: '78 m/s',
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: StatBox(
                                            label: 'Min débit',
                                            value: '78 m/s',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: StatBox(
                                            label: 'Min débit',
                                            value: '78 m/s',
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: StatBox(
                                            label: 'Min débit',
                                            value: '78 m/s',
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

                      SizedBox(width: 32),

                      // Colonne Droite : Graphiques
                      Expanded(
                        child: Container(
                          child: Column(
                            children: [
                              Expanded(
                                child: HydroLineChart(
                                  title: 'Débit',
                                  xValues: [0, 1, 2, 3],
                                  yValues: [10, 25, 30, 20],
                                ),
                              ),
                              SizedBox(height: 32),
                              Expanded(
                                child: HydroLineChart(
                                  title: 'Hauteur',
                                  xValues: [0, 1, 2, 3],
                                  yValues: [10, 25, 2, 20],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
