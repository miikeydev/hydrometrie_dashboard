import 'package:flutter/material.dart';
import 'station.dart';
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
          padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32, top: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Hydrométrie Dashboard", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 340,
                        child: Center(
                          child: StationInfoPanel(
                            stationCode: 'V350401201',
                            stationAddress: '745.0 Mesurée\nNon qualifiée\nBrute',
                            stationCoordinates: '45.235°N 4.633°E',
                            initialDateRange: DateTimeRange(
                              start: DateTime.now().subtract(const Duration(days: 2)),
                              end: DateTime.now(),
                            ),
                            stationSuggestions: const ['V350401201', 'Station A', 'Station B'],
                            onSearchSelected: (value) {
                              // Do something with the selected station code
                            },
                            onDateRangeChanged: (dateRange) {
                              // Do something with the chosen date range
                            },
                          )
                          ,
                        ),
                      ),
                      SizedBox(
                        width: 32,
                      ),
                      Container(
                        width: 300,
                        child: Column(children: [
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: CircleGaugeCard(
                                    value: 136,        // e.g. current measured value
                                    min: 0,           // minimal expected
                                    max: 200,         // maximal expected
                                    unit: 'm³/s',     // e.g. "m³/s"
                                    label: 'Moyenne du débit',
                                  ),
                                ),
                                SizedBox(
                                  height: 32,
                                ),
                                Expanded(
                                  child: CircleGaugeCard(
                                    value: 2.57,        // e.g. current measured value
                                    min: 0,           // minimal expected
                                    max: 10,         // maximal expected
                                    unit: 'm',     // e.g. "m³/s"
                                    label: 'Moyenne de hauteur',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 32,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: Row(children: [
                                    Expanded(
                                      child: StatBox(
                                        label: 'Min débit',
                                        value: '78 m/s',
                                      ),
                                    ),
                                    SizedBox(
                                      width: 16,
                                    ),
                                    Expanded(
                                      child: StatBox(
                                        label: 'Min débit',
                                        value: '78 m/s',
                                      ),
                                    ),
                                  ],
                                  ),
                                ),
                                SizedBox(
                                  height: 16,
                                ),
                                Expanded(
                                  child: Row(children: [
                                    Expanded(
                                      child: StatBox(
                                        label: 'Min débit',
                                        value: '78 m/s',
                                      ),
                                    ),
                                    SizedBox(
                                      width: 16,
                                    ),
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
                        
                        ],),
                      ),
                  
                      SizedBox(
                        width: 32,
                      ),
                      Expanded(
                        child: Container(
                          child: Column(children: [
                            Expanded(
                              child: HydroLineChart(
                                title: 'Débit',
                                xValues: [0, 1, 2, 3],
                                yValues: [10, 25, 30, 20],
                              ),
                            ),
                            SizedBox(
                              height: 32,
                            ),
                            Expanded(
                              child: HydroLineChart(
                                title: 'Hauteur',
                                xValues: [0, 1, 2, 3],
                                yValues: [10, 25, 2, 20],
                              ),
                            ),
                          ],),
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