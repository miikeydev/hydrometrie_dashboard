import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'station.dart';
import 'providers.dart';
import 'gaugeChart.dart' as gauge;
import 'statBox.dart' as statbox;
import 'graph.dart' as graph;

class DashboardPage extends ConsumerWidget {
  const DashboardPage({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupération des observations depuis l'API en fonction de la station et date sélectionnées
    final observationsAsync = ref.watch(observationsProvider);
    
    // Transformation exemple pour alimenter les graphiques
    List<double> xValues = [0, 1, 2, 3];
    List<double> yValuesDebit = [10, 25, 30, 20];
    List<double> yValuesHauteur = [10, 25, 2, 20];
    
    // Si le FutureProvider renvoie des données, on les transforme pour alimenter nos graphiques
    if (observationsAsync.whenData((data) => data).valueOrNull != null) {
      final data = observationsAsync.value!;
      // Adaptation selon la structure renvoyée par l'API
      xValues = List.generate(data.length, (index) => index.toDouble());
      yValuesDebit = data.map<double>((obs) {
        return (obs['resultat_obs'] is num) ? obs['resultat_obs'].toDouble() : 0.0;
      }).toList();
      // On réutilise yValuesDebit comme exemple pour "hauteur" (à adapter réellement)
      yValuesHauteur = yValuesDebit;
    }
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32, top: 16),
        child: Column(
          children: [
            // Titre
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
                Text(
                  "Hydrométrie Dashboard",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Corps principal
            Expanded(
              child: Row(
                children: [
                  // Barre de filtre
                  Container(
                    width: 270,
                    // Retirer const si vous passez des valeurs non const
                    child: StationInfoPanel(
                      initialDateRange: DateTimeRange(
                        start: DateTime.now().subtract(const Duration(days: 5)),
                        end: DateTime.now(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),

                  // Colonne Gauche : Gauges et StatBox
                  Container(
                    width: 250,
                    child: Column(
                      children: [
                        // Gauges
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: gauge.CircleGaugeCard(
                                  value: 136,
                                  min: 0,
                                  max: 200,
                                  unit: 'm³/s',
                                  label: 'Moyenne du débit',
                                ),
                              ),
                              const SizedBox(height: 32),
                              Expanded(
                                child: gauge.CircleGaugeCard(
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
                        const SizedBox(height: 32),

                        // StatBoxes
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: statbox.StatBox(
                                        label: 'Min débit',
                                        value: '78 m/s',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: statbox.StatBox(
                                        label: 'Min débit',
                                        value: '78 m/s',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: statbox.StatBox(
                                        label: 'Min débit',
                                        value: '78 m/s',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: statbox.StatBox(
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

                  const SizedBox(width: 32),

                  // Colonne Droite : Graphiques
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: graph.HydroLineChart(
                            title: 'Débit',
                            xValues: xValues,
                            yValues: yValuesDebit,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Expanded(
                          child: graph.HydroLineChart(
                            title: 'Hauteur',
                            xValues: xValues,
                            yValues: yValuesHauteur,
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
}
