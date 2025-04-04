import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

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
  // Vous pouvez ajuster le paramètre de requête selon l’API (ici on recherche par libellé de station)
  final response = await dio.get(
    'https://hubeau.eaufrance.fr/api/v2/hydrometrie/referentiel/stations',
    queryParameters: {
      'libelle_station': searchText,
      'size': 20, // Limite à 20 résultats
    },
  );
  final data = response.data['data'] as List<dynamic>;
  return data.map((e) => e as Map<String, dynamic>).toList();
});

// Provider pour récupérer les observations (par exemple, en temps réel) pour la station sélectionnée et la plage de dates
final observationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final station = ref.watch(selectedStationProvider);
  final dateRange = ref.watch(dateRangeProvider);
  if (station == null) {
    return [];
  }
  final codeStation = station['code_station'];
  final dio = Dio();
  final response = await dio.get(
    'https://hubeau.eaufrance.fr/api/v2/hydrometrie/observations_tr',
    queryParameters: {
      'code_station': codeStation,
      'date_debut': dateRange.start.toIso8601String(),
      'date_fin': dateRange.end.toIso8601String(),
      'size': 1000,
    },
  );
  final data = response.data['data'] as List<dynamic>;
  return data.map((e) => e as Map<String, dynamic>).toList();
});
