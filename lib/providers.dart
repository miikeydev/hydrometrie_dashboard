import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// 1) Providers existants (recherche, station sélectionnée, dateRange, etc.)
// ---------------------------------------------------------------------

// Texte de recherche pour le nom de station
final searchTextProvider = StateProvider<String>((ref) => "");

// Plage de dates sélectionnée
final dateRangeProvider = StateProvider<DateTimeRange>((ref) {
  return DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 5)),
    end: DateTime.now(),
  );
});

// Station sélectionnée (on stocke tout l'objet JSON)
final selectedStationProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Suggestions de stations (référentiel)
final stationSuggestionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      
  
  final searchText = ref.watch(searchTextProvider);
  developer.log("📡 API call déclenchée avec : $searchText", name: "stationSuggestionsProvider");

  final dio = Dio();
  final response = await dio.get(
    'https://hubeau.eaufrance.fr/api/v2/hydrometrie/referentiel/stations',
    queryParameters: {
      'libelle_station': searchText,
      'en_service': 1, // Filtrer uniquement les stations en service
      'size': 100, // Limite à 100 résultats
    },
  );
  developer.log("📥 Réponse brute : ${response.data['data'].length} résultats", name: "stationSuggestionsProvider");

  final data = response.data['data'] as List<dynamic>;
  final stations = data
      .map((e) => e as Map<String, dynamic>)
      .where((station) => station['libelle_station'] != null) // Filtrer les stations valides
      .toList();

  // Vérification des données pour chaque station
  final validStations = <Map<String, dynamic>>[];
  for (final station in stations) {
    final hasData = await _hasStationData(station['code_station'], dio);
    if (hasData) {
      validStations.add(station);
    }
  }

  developer.log("✅ Stations valides avec données : ${validStations.length}", name: "stationSuggestionsProvider");


  return validStations;
});

// Fonction pour vérifier si une station a des données de débit ou de hauteur
Future<bool> _hasStationData(String codeStation, Dio dio) async {
  try {
    final response = await dio.get(
      'https://hubeau.eaufrance.fr/api/v2/hydrometrie/observations_tr',
      queryParameters: {
        'code_entite': codeStation,
        'size': 1, // Vérifie uniquement si au moins une donnée existe
      },
    );
    final data = response.data['data'] as List<dynamic>;
    return data.isNotEmpty;
  } catch (e) {
    return false; // En cas d'erreur, considérer qu'il n'y a pas de données
  }
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

  final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  final dateDebut = dateFormat.format(dateRange.start);
  final dateFin = dateFormat.format(dateRange.end);

  developer.log(
    'Récupération obs_tr pour la station: $codeStation',
    name: 'observationsProvider',
  );
  developer.log('Période: $dateDebut -> $dateFin', name: 'observationsProvider');

  try {
    final dio = Dio();
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
    final List<Map<String, dynamic>> observations =
        data.map((e) => e as Map<String, dynamic>).toList();

    // On filtre pour s'assurer que c'est bien la bonne station
    final filtered = observations.where((obs) {
      return obs['code_station'] == codeStation || obs['code_site'] == codeSite;
    }).toList();

    developer.log(
      'Nombre total d\'observations TR filtrées: ${filtered.length}',
      name: 'observationsProvider',
    );

    return filtered;
  } catch (error, stack) {
    developer.log(
      'Erreur lors de la récupération des observations_tr: $error',
      name: 'observationsProvider',
      error: error,
      stackTrace: stack,
    );
    return [];
  }
});

// ---------------------------------------------------------------------
// 3) Nouveau Provider pour obs_elab
//    => Renvoie QmnJ ou QmM en fonction de la durée
// ---------------------------------------------------------------------
final observationsElabProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final station = ref.watch(selectedStationProvider);
  final dateRange = ref.watch(dateRangeProvider);

  if (station == null) {
    return [];
  }

  final codeStation = station['code_station'];
  final codeSite = station['code_site'];

  // Durée en jours
  final nbJours = dateRange.end.difference(dateRange.start).inDays;
  // Si <= 90 jours, on utilise QmnJ, sinon QmM
  final grandeurElab = nbJours <= 90 ? "QmnJ" : "QmM";

  try {
    final dio = Dio();
    final response = await dio.get(
      'https://hubeau.eaufrance.fr/api/v2/hydrometrie/obs_elab',
      queryParameters: {
        // Vous pouvez choisir d’utiliser codeStation ou codeSite
        'code_entite': codeStation,
        'grandeur_hydro_elab': grandeurElab,
        'date_debut_obs_elab': dateRange.start.toIso8601String(),
        'date_fin_obs_elab': dateRange.end.toIso8601String(),
        'size': 1000,
      },
    );

    final data = response.data['data'] as List<dynamic>;

    // Transformation : on renomme date et valeur pour rester cohérent avec l’UI
    // et on conserve le type de mesure dans "grandeur_mesure"
    final List<Map<String, dynamic>> observations = data.map((item) {
      return {
        'code_station': item['code_station'] ?? codeStation,
        'code_site': item['code_site'] ?? codeSite,
        'date_obs': item['date_obs_elab'],
        'resultat_obs': item['resultat_obs_elab'],
        // Pour l’UI on force "Q", mais on garde en plus le type original
        'grandeur_hydro': 'Q',
        'grandeur_mesure': item['grandeur_hydro_elab'], // "QmM" ou "QmnJ"
      };
    }).toList();

    return observations;
  } catch (e, stack) {
    developer.log('Erreur obs_elab: $e', error: e, stackTrace: stack);
    return [];
  }
});


// ---------------------------------------------------------------------
// 4) Provider COMBINÉ : si la plage <= 30j => on utilise obs_tr
//    sinon => on utilise obs_elab
// ---------------------------------------------------------------------
final combinedObservationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dateRange = ref.watch(dateRangeProvider);
  final nbJours = dateRange.end.difference(dateRange.start).inDays;

  // Seuil : 30 jours
  if (nbJours <= 30) {
    // On se base sur observations TR
    return ref.watch(observationsProvider.future);
  } else {
    // Au-delà de 30 j, on prend obs_elab
    return ref.watch(observationsElabProvider.future);
  }
});

// ---------------------------------------------------------------------
// 5) Providers de commodité : débit + hauteur
//    (Ils vont piocher dans "combinedObservationsProvider" désormais)
// ---------------------------------------------------------------------

final debitObservationsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final observationsAsync = ref.watch(combinedObservationsProvider);
  return observationsAsync.maybeWhen(
    data: (observations) =>
        observations.where((obs) => obs['grandeur_hydro'] == 'Q').toList(),
    orElse: () => [],
  );
});

// Pour la hauteur (H), si vous en avez aussi côté obs_elab, vous pourriez l’adapter.
// Ici, on suppose qu’on récupère la hauteur via l’endpoint TR si existant, ou qu’on
// fera un traitement similaire dans obs_elab si vous avez des HmnJ/HmM, etc.
final hauteurObservationsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final observationsAsync = ref.watch(combinedObservationsProvider);
  return observationsAsync.maybeWhen(
    data: (observations) =>
        observations.where((obs) => obs['grandeur_hydro'] == 'H').toList(),
    orElse: () => [],
  );
});

