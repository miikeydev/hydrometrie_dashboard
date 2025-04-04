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
    // Récupération des observations depuis l'API en fonction de la station et date sélectionnées
    final observationsAsync = ref.watch(observationsProvider);
    final selectedStation = ref.watch(selectedStationProvider);
    final dateRange = ref.watch(dateRangeProvider);
    
    // Initialisation des valeurs par défaut pour les graphiques
    List<DateTime> xValuesDebitDates = [];
    List<double> yValuesDebit = [];
    List<DateTime> xValuesHauteurDates = [];
    List<double> yValuesHauteur = [];

    // Variables pour les statistiques
    double debitMoyen = 0.0;
    double hauteurMoyenne = 0.0;
    String minDebit = "N/A";
    String maxDebit = "N/A";
    String minHauteur = "N/A";
    String maxHauteur = "N/A";
    
    // Titre de l'application avec le nom de la station si sélectionnée
    String dashboardTitle = "Hydrométrie Dashboard";
    if (selectedStation != null) {
      final stationName = selectedStation['libelle_station'] ?? "";
      if (stationName.isNotEmpty) {
        dashboardTitle += " - $stationName";
      }
    }
    
    // Si le FutureProvider renvoie des données, on les transforme pour alimenter nos graphiques
    if (observationsAsync.whenData((data) => data).valueOrNull != null) {
      final allData = observationsAsync.value!;
      
      // Séparation des données de débit (Q) et hauteur (H)
      final debitData = allData.where((obs) => obs['grandeur_hydro'] == 'Q').toList();
      final hauteurData = allData.where((obs) => obs['grandeur_hydro'] == 'H').toList();
      
      developer.log('Données de débit: ${debitData.length} observations', name: 'dashboard');
      developer.log('Données de hauteur: ${hauteurData.length} observations', name: 'dashboard');
      
      // Traitement des données de débit
      if (debitData.isNotEmpty) {
        // Trier les données par date
        debitData.sort((a, b) => DateTime.parse(a['date_obs']).compareTo(DateTime.parse(b['date_obs'])));
        
        // Créer les x (dates) et y (valeurs) pour le graphique de débit
        xValuesDebitDates = debitData
            .map<DateTime>((obs) => DateTime.parse(obs['date_obs']))
            .toList();
        
        yValuesDebit = debitData.map<double>((obs) {
          return (obs['resultat_obs'] is num) ? obs['resultat_obs'].toDouble() : 0.0;
        }).toList();
        
        // Calculer les statistiques de débit
        final debitValues = yValuesDebit.where((value) => value > 0).toList();
        if (debitValues.isNotEmpty) {
          debitMoyen = debitValues.reduce((a, b) => a + b) / debitValues.length;
          final minDebitValue = debitValues.reduce((a, b) => a < b ? a : b);
          final maxDebitValue = debitValues.reduce((a, b) => a > b ? a : b);
          minDebit = formatValue(minDebitValue, 'm³/s');
          maxDebit = formatValue(maxDebitValue, 'm³/s');
        }
      }
      
      // Traitement des données de hauteur
      if (hauteurData.isNotEmpty) {
        // Trier les données par date
        hauteurData.sort((a, b) => DateTime.parse(a['date_obs']).compareTo(DateTime.parse(b['date_obs'])));
        
        // Créer les x (dates) et y (valeurs) pour le graphique de hauteur
        xValuesHauteurDates = hauteurData
            .map<DateTime>((obs) => DateTime.parse(obs['date_obs']))
            .toList();
        
        yValuesHauteur = hauteurData.map<double>((obs) {
          return (obs['resultat_obs'] is num) ? obs['resultat_obs'].toDouble() : 0.0;
        }).toList();
        
        // Calculer les statistiques de hauteur
        final hauteurValues = yValuesHauteur.where((value) => value > 0).toList();
        if (hauteurValues.isNotEmpty) {
          hauteurMoyenne = hauteurValues.reduce((a, b) => a + b) / hauteurValues.length;
          final minHauteurValue = hauteurValues.reduce((a, b) => a < b ? a : b);
          final maxHauteurValue = hauteurValues.reduce((a, b) => a > b ? a : b);
          minHauteur = formatValue(minHauteurValue, 'm');
          maxHauteur = formatValue(maxHauteurValue, 'm');
        }
      }
    }
    
    // Calculer la période pour le titre des graphiques
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
        padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32, top: 16),
        child: Column(
          children: [
            // Titre
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    dashboardTitle,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Corps principal
            Expanded(
              child: Row(
                children: [
                  // Barre de filtre
                  SizedBox(
                    width: 270,
                    child: StationInfoPanel(
                      initialDateRange: DateTimeRange(
                        start: DateTime.now().subtract(const Duration(days: 5)),
                        end: DateTime.now(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),

                  // Colonne Gauche : Gauges et StatBox
                  SizedBox(
                    width: 250,
                    child: Column(
                      children: [
                        // Gauges
                        Expanded(
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
                              const SizedBox(height: 32),
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
                                        value: minDebit,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: statbox.StatBox(
                                        label: 'Max débit',
                                        value: maxDebit,
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
                                        label: 'Min hauteur',
                                        value: minHauteur,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: statbox.StatBox(
                                        label: 'Max hauteur',
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

                  const SizedBox(width: 32),

                  // Colonne Droite : Graphiques
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: graph.HydroLineChart(
                            title: 'Débit (m³/s)$periodLabel',
                            dates: xValuesDebitDates,
                            values: yValuesDebit,
                            startDate: dateRange.start,
                            endDate: dateRange.end,
                            isHeightChart: false, // C'est un graphique de débit
                          ),
                        ),
                        const SizedBox(height: 32),
                        Expanded(
                          child: graph.HydroLineChart(
                            title: 'Hauteur (m)$periodLabel',
                            dates: xValuesHauteurDates,
                            values: yValuesHauteur,
                            startDate: dateRange.start,
                            endDate: dateRange.end,
                            isHeightChart: true, // C'est un graphique de hauteur
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
  
  // Fonction pour formater les valeurs de façon plus lisible (avec K, M, etc.)
  String formatValue(double value, String unit) {
    String formattedValue;
    if (value >= 1000000) {
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
