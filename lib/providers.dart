import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

// Provider pour le texte de recherche (ex : nom de la station ou de la commune)
final searchTextProvider = StateProvider<String>((ref) => "");

// Provider pour la plage de dates
final dateRangeProvider = StateProvider<DateTimeRange>((ref) {
  return DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 5)),
    end: DateTime.now(),
  );
});

// Provider pour stocker la station sélectionnée (on stocke ici toute la Map renvoyée par l'API)
final selectedStationProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Provider pour récupérer les suggestions de stations en fonction du texte de recherche
final stationSuggestionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final searchText = ref.watch(searchTextProvider);
  if (searchText.isEmpty) {
    return [];
  }
  final dio = Dio();
  // Vous pouvez ajuster le paramètre de requête selon l'API (ici on recherche par libellé de station)
  final response = await dio.get(
    'https://hubeau.eaufrance.fr/api/v2/hydrometrie/referentiel/stations',
    queryParameters: {
      'libelle_station': searchText,
      'size': 20, // Limite à 20 résultats
    },
  );
  final data = response.data['data'] as List<dynamic>;
  final stations = data.map((e) => e as Map<String, dynamic>).toList();

  // Ajout de la logique de similarité
  return stations.where((station) {
    final stationName = (station['libelle_station'] ?? '').toLowerCase();
    return stationName.contains(searchText.toLowerCase()) ||
        _isSimilar(stationName, searchText.toLowerCase());
  }).toList();
});

bool _isSimilar(String stationName, String searchText) {
  // Implémentez ici votre logique de similarité (exemple : distance de Levenshtein)
  return false; // Remplacez par votre logique
}

// Provider pour récupérer les observations (par exemple, en temps réel) pour la station sélectionnée et la plage de dates
final observationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final station = ref.watch(selectedStationProvider);
  final dateRange = ref.watch(dateRangeProvider);
  if (station == null) {
    return [];
  }
  
  final codeSite = station['code_site'];
  final codeStation = station['code_station'];
  final libelle = station['libelle_station'];
  final dio = Dio();
  
  // Formatage des dates pour l'affichage dans les logs
  final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  final dateDebut = dateFormat.format(dateRange.start);
  final dateFin = dateFormat.format(dateRange.end);
  
  developer.log('Récupération des observations pour la station: $libelle ($codeStation)',
      name: 'observationsProvider');
  developer.log('Période: $dateDebut à $dateFin', name: 'observationsProvider');
  
  try {
    final response = await dio.get(
      'https://hubeau.eaufrance.fr/api/v2/hydrometrie/observations_tr',
      queryParameters: {
        'code_entite': codeStation,
        'date_debut_obs': dateRange.start.toIso8601String(),
        'date_fin_obs': dateRange.end.toIso8601String(),
        'size': 1000,
      },
    );
    
    final data = response.data['data'] as List<dynamic>;
    final List<Map<String, dynamic>> observations = data.map((e) => e as Map<String, dynamic>).toList();
    
    // Vérification que les données correspondent bien à la station sélectionnée
    final filteredObservations = observations.where((obs) => 
      obs['code_station'] == codeStation || 
      obs['code_site'] == codeSite).toList();
    
    if (filteredObservations.isEmpty) {
      developer.log('Aucune observation trouvée pour cette station', name: 'observationsProvider');
      return [];
    }
    
    // Afficher les 2 premières observations dans la console pour debug
    developer.log('Nombre total d\'observations: ${filteredObservations.length}', name: 'observationsProvider');
    if (filteredObservations.isNotEmpty) {
      final firstObs = filteredObservations.first;
      developer.log('Première observation: Station=${firstObs['code_station']}, Date=${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(firstObs['date_obs']))}, Valeur=${firstObs['resultat_obs']}, Type=${firstObs['grandeur_hydro']}', name: 'observationsProvider');
      if (filteredObservations.length > 1) {
        final secondObs = filteredObservations[1];
        developer.log('Deuxième observation: Station=${secondObs['code_station']}, Date=${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(secondObs['date_obs']))}, Valeur=${secondObs['resultat_obs']}, Type=${secondObs['grandeur_hydro']}', name: 'observationsProvider');
      }
    }
    
    return filteredObservations;
  } catch (error) {
    developer.log('Erreur lors de la récupération des observations: $error', name: 'observationsProvider', error: error);
    return [];
  }
});

// Provider qui distingue les observations de débit (Q) et hauteur (H)
final debitObservationsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final observationsAsync = ref.watch(observationsProvider);
  return observationsAsync.maybeWhen(
    data: (observations) => observations.where((obs) => obs['grandeur_hydro'] == 'Q').toList(),
    orElse: () => [],
  );
});

final hauteurObservationsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final observationsAsync = ref.watch(observationsProvider);
  return observationsAsync.maybeWhen(
    data: (observations) => observations.where((obs) => obs['grandeur_hydro'] == 'H').toList(),
    orElse: () => [],
  );
});
