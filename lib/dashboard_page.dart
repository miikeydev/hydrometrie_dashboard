import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'station.dart';
import 'providers.dart';
import 'gaugeChart.dart' as gauge;
import 'statBox.dart' as statbox;
import 'graph.dart' as graph;
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'water_level_widget.dart';

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
    String minDebit = "-";
    String maxDebit = "-";
    String minHauteur = "-";
    String maxHauteur = "-";

    if (observationsAsync.whenData((data) => data).valueOrNull != null) {
      final allData = observationsAsync.value!;

      // On extrait les observations de débit et de hauteur
      final debitData = allData.where((obs) => obs['grandeur_hydro'] == 'Q').toList();
      final hauteurData = allData.where((obs) => obs['grandeur_hydro'] == 'H').toList();

      developer.log('Données de débit: ${debitData.length} observations', name: 'dashboard');
      developer.log('Données de hauteur: ${hauteurData.length} observations', name: 'dashboard');

      // Traitement des données de débit
      if (debitData.isNotEmpty) {
        // Tri des données par date
        debitData.sort((a, b) => DateTime.parse(a['date_obs'])
            .compareTo(DateTime.parse(b['date_obs'])));
            
        // Extraction des dates et des valeurs de débit
        xValuesDebitDates = debitData
            .map<DateTime>((obs) => DateTime.parse(obs['date_obs']))
            .toList();
        yValuesDebit = debitData.map<double>((obs) {
          return (obs['resultat_obs'] is num)
              ? obs['resultat_obs'].toDouble()
              : 0.0;
        }).toList();

        if (yValuesDebit.isNotEmpty) {
          debitMoyen = yValuesDebit.reduce((a, b) => a + b) / yValuesDebit.length; // Moyenne incluant les négatifs
          final minDebitValue = yValuesDebit.reduce((a, b) => a < b ? a : b);
          final maxDebitValue = yValuesDebit.reduce((a, b) => a > b ? a : b);
          minDebit = formatValue(minDebitValue, 'm³/s');
          maxDebit = formatValue(maxDebitValue, 'm³/s');
        }
      }

      // Traitement des données de hauteur (inchangé)
      if (hauteurData.isNotEmpty) {
        hauteurData.sort((a, b) => DateTime.parse(a['date_obs'])
            .compareTo(DateTime.parse(b['date_obs'])));
        xValuesHauteurDates = hauteurData
            .map<DateTime>((obs) => DateTime.parse(obs['date_obs']))
            .toList();
        yValuesHauteur = hauteurData.map<double>((obs) {
          return (obs['resultat_obs'] is num)
              ? obs['resultat_obs'].toDouble()
              : 0.0;
        }).toList();


        if (yValuesHauteur.isNotEmpty) {
          hauteurMoyenne = yValuesHauteur.reduce((a, b) => a + b) / yValuesHauteur.length; // Moyenne incluant les négatifs
          final minHauteurValue = yValuesHauteur.reduce((a, b) => a < b ? a : b);
          final maxHauteurValue = yValuesHauteur.reduce((a, b) => a > b ? a : b);

          minHauteur = formatValue(minHauteurValue, 'm');
          maxHauteur = formatValue(maxHauteurValue, 'm');
        }
      }
    }

    String periodLabel = "";

    String dashboardTitle = "Hydrométrie Dashboard";
    if (selectedStation != null) {
      final stationName = selectedStation['libelle_station'] ?? "";
      if (stationName.isNotEmpty) {
        dashboardTitle += " - $stationName";
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200], // Fond de couleur gris clair
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
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
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

                    width: 400, // Augmenté de 350 à 400 pour plus d'espace

                    child: StationInfoPanel(
                      initialDateRange: DateTimeRange(
                        start: DateTime.now().subtract(const Duration(days: 5)),
                        end: DateTime.now(),
                      ),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Limite un mois en arrière
                      lastDate: DateTime.now().add(const Duration(days: 30)), // Limite un mois en avant
                      maxSelectableDate: DateTime.now(), // Empêche la sélection au-delà de la date actuelle
                    ),
                  ),

                  const SizedBox(width: 16), // Espacement ajusté

                  SizedBox(
                    width: 300, // Augmenté de 260 à 300
                    child: Column(
                      children: [
                        Expanded(
                          flex: 6, // Augmente la proportion de la section KPI
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: LinearGradient(
                                          colors: calculateTrend(yValuesDebit) > 0
                                              ? [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.1)]
                                              : calculateTrend(yValuesDebit) < 0
                                                  ? [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.1)]
                                                  : [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.1)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(
                                            Icons.water_drop,
                                            color: Colors.black,
                                            size: 24,
                                          ),
                                          calculateTrend(yValuesDebit) != 0
                                              ? Icon(
                                                  calculateTrend(yValuesDebit) > 0
                                                      ? Icons.north_east
                                                      : Icons.south_east,
                                                  color: Colors.black,
                                                  size: 24,
                                                )
                                              : const Text(
                                                  '-', // Remplacement de '--' par '-'
                                                  style: TextStyle(color: Colors.black, fontSize: 16),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: LinearGradient(
                                          colors: calculateTrend(yValuesHauteur) > 0
                                              ? [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.1)]
                                              : calculateTrend(yValuesHauteur) < 0
                                                  ? [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.1)]
                                                  : [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.1)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(
                                            Icons.height,
                                            color: Colors.black,
                                            size: 24,
                                          ),
                                          calculateTrend(yValuesHauteur) != 0
                                              ? Icon(
                                                  calculateTrend(yValuesHauteur) > 0
                                                      ? Icons.north_east
                                                      : Icons.south_east,
                                                  color: Colors.black,
                                                  size: 24,
                                                )
                                              : const Text(
                                                  '-', // Remplacement de '--' par '-'
                                                  style: TextStyle(color: Colors.black, fontSize: 16),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: WaterLevelWidget(
                                        // Toujours montrer au moins 10% de remplissage pour les cas sans données
                                        fillPercent: (debitMoyen > 0 && _isValidDouble(minDebit) && _isValidDouble(maxDebit))
                                            ? (() {
                                                try {
                                                  final minVal = _extractNumericValue(minDebit);
                                                  final maxVal = _extractNumericValue(maxDebit);
                                                  
                                                  // Si min et max sont égaux, utiliser une position fixe (50%)
                                                  if (maxVal == minVal) return 0.5;
                                                  
                                                  // Calcul du pourcentage comme position relative entre min et max
                                                  return ((debitMoyen - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
                                                } catch (e) {
                                                  return 0.1; // 10% par défaut en cas d'erreur
                                                }
                                              })()
                                            : 0.1, // 10% pour les cas sans données
                                        size: double.infinity,
                                        formattedValue: debitMoyen > 0 ? formatValue(debitMoyen, 'm³/s') : 'N/A',
                                        percentage: (debitMoyen > 0 && _isValidDouble(minDebit) && _isValidDouble(maxDebit)) 
                                            ? (() {
                                                try {
                                                  final minVal = _extractNumericValue(minDebit);
                                                  final maxVal = _extractNumericValue(maxDebit);
                                                  
                                                  if (maxVal == minVal) return "50%";
                                                  
                                                  final percentValue = ((debitMoyen - minVal) / (maxVal - minVal) * 100).clamp(0.0, 100.0);
                                                  return "${percentValue.toStringAsFixed(0)}%";
                                                } catch (e) {
                                                  return "-%";
                                                }
                                              })()
                                            : "--%",
                                        title: "Moyenne Q", // Titre spécifique pour le widget du débit
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: WaterLevelWidget(
                                        fillPercent: (hauteurMoyenne > 0 && _isValidDouble(minHauteur) && _isValidDouble(maxHauteur))
                                            ? (() {
                                                try {
                                                  final minVal = _extractNumericValue(minHauteur);
                                                  final maxVal = _extractNumericValue(maxHauteur);
                                                  
                                                  // Si min et max sont égaux, utiliser une position fixe (50%)
                                                  if (maxVal == minVal) return 0.5;
                                                  
                                                  // Calcul du pourcentage comme position relative entre min et max
                                                  return ((hauteurMoyenne - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
                                                } catch (e) {
                                                  return 0.1; // 10% par défaut en cas d'erreur
                                                }
                                              })()
                                            : 0.1, // 10% pour les cas sans données
                                        size: double.infinity,
                                        formattedValue: hauteurMoyenne > 0 ? formatValue(hauteurMoyenne, 'm') : 'N/A',
                                        percentage: (hauteurMoyenne > 0 && _isValidDouble(minHauteur) && _isValidDouble(maxHauteur))
                                            ? (() {
                                                try {
                                                  final minVal = _extractNumericValue(minHauteur);
                                                  final maxVal = _extractNumericValue(maxHauteur);
                                                  
                                                  if (maxVal == minVal) return "50%";
                                                  
                                                  final percentValue = ((hauteurMoyenne - minVal) / (maxVal - minVal) * 100).clamp(0.0, 100.0);
                                                  return "${percentValue.toStringAsFixed(0)}%";
                                                } catch (e) {
                                                  return "-%";
                                                }
                                              })()
                                            : "--%",
                                        title: "Moyenne H", // Titre spécifique pour le widget de la hauteur
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          flex: 4, // Ajuste la proportion des statistiques
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


                  const SizedBox(width: 16), // Espacement ajusté


                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 1,
                          child: graph.HydroLineChart(
                            title: 'Évolution Débit', // Titre simplifié sans dates
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
                            title: 'Évolution Hauteur', // Titre simplifié sans dates
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

  double calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;
    return values.last - values.first;
  }

  String formatValue(double value, String unit) {
    String formattedValue;
    if (value.isNaN || value.isInfinite) {
      return "-";
    } else if (value >= 1000000) {
      formattedValue = '${(value / 1000000).toStringAsFixed((value % 1000000 == 0) ? 0 : 1)}M';
    } else if (value >= 1000) {
      formattedValue = '${(value / 1000).toStringAsFixed((value % 1000 == 0) ? 0 : 1)}k';
    } else if (value % 1 == 0) {
      formattedValue = value.toStringAsFixed(0); // Affiche uniquement la partie entière
    } else {
      formattedValue = value.toStringAsFixed(2);
    }
    return '$formattedValue $unit';
  }

  bool _isValidDouble(String value) {
    if (value == "-") return false;
    try {
      // Gestion des formats avec k et M
      String numStr = value.split(' ')[0];
      
      // Remplacer les virgules par des points si nécessaire
      numStr = numStr.replaceAll(',', '.');
      
      // Gérer les suffixes k et M
      if (numStr.contains('k') || numStr.contains('K')) {
        numStr = numStr.replaceAll('k', '').replaceAll('K', '');
        double baseValue = double.parse(numStr);
        return baseValue * 1000 != 0; // On vérifie seulement que la valeur n'est pas zéro
      } 
      else if (numStr.contains('m') || numStr.contains('M')) {
        numStr = numStr.replaceAll('m', '').replaceAll('M', '');
        double baseValue = double.parse(numStr);
        return baseValue * 1000000 != 0; // On vérifie seulement que la valeur n'est pas zéro
      }
      
      // Cas standard - accepter les valeurs négatives
      return double.parse(numStr) != 0; // On vérifie seulement que la valeur n'est pas zéro
    } catch (e) {
      return false;
    }
  }

  double _extractNumericValue(String formattedValue) {
    if (formattedValue == "-") return 0.0;
    
    // Extraire la partie numérique (avant l'unité)
    String numericPart = formattedValue.split(' ')[0].trim();
    
    // Traiter le signe négatif explicitement
    bool isNegative = numericPart.startsWith('-');
    if (isNegative) {
      numericPart = numericPart.substring(1); // Enlever le signe négatif pour le traitement
    }
    
    double value = 0.0;
    
    // Gérer le cas des milliers (k)
    if (numericPart.contains('k') || numericPart.contains('K')) {
      numericPart = numericPart.replaceAll('k', '').replaceAll('K', '');
      value = double.parse(numericPart) * 1000;
    }
    // Gérer le cas des millions (M)
    else if (numericPart.contains('M')) {
      numericPart = numericPart.replaceAll('M', '');
      value = double.parse(numericPart) * 1000000;
    }
    // Cas de base - juste un nombre
    else {
      value = double.parse(numericPart);
    }
    
    // Réappliquer le signe négatif si nécessaire
    return isNegative ? -value : value;
  }
}
