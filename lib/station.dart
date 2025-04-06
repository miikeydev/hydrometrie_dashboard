import 'package:flutter/material.dart';
import 'package:flutter_date_pickers/flutter_date_pickers.dart' as dp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'dart:async';

class StationInfoPanel extends ConsumerStatefulWidget {
  final String initialSearchText;
  final DateTimeRange initialDateRange;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime maxSelectableDate;

  const StationInfoPanel({
    Key? key,
    this.initialSearchText = '',
    required this.initialDateRange,
    required this.firstDate,
    required this.lastDate,
    required this.maxSelectableDate,
  }) : super(key: key);

  @override
  ConsumerState<StationInfoPanel> createState() => _StationInfoPanelState();
}

class _StationInfoPanelState extends ConsumerState<StationInfoPanel> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _fieldKey = GlobalKey();
  final MapController _mapController = MapController(); // Initialisation du MapController
  late dp.DatePeriod _currentPeriod;
  bool _showClearButton = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final validStartDate = today.isBefore(widget.firstDate) ? widget.firstDate : today;
    final validEndDate = today.isAfter(widget.lastDate) ? widget.lastDate : today;

    _currentPeriod = dp.DatePeriod(validStartDate, validEndDate);
    _searchController.text = widget.initialSearchText;
    _showClearButton = _searchController.text.isNotEmpty;

    _searchController.addListener(() {
      if (_searchDebounce?.isActive ?? false) {
        _searchDebounce!.cancel();
      }
      _searchDebounce = Timer(const Duration(milliseconds: 200), () {
        ref.read(searchTextProvider.notifier).state = _searchController.text;
      });
      setState(() {
        _showClearButton = _searchController.text.isNotEmpty;
      });
    });

    Future.microtask(() {
      ref.read(dateRangeProvider.notifier).state = DateTimeRange(
        start: validStartDate,
        end: validEndDate,
      );
      ref.read(searchTextProvider.notifier).state = widget.initialSearchText;

      // Charger la France entière au début
      _animatedMapMove(latlong2.LatLng(47.0, 2.0), 5); // Zoom adapté pour afficher la France entière
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      final today = DateTime.now();
      final validStartDate = today.isBefore(widget.firstDate) ? widget.firstDate : today;
      final validEndDate = today.isAfter(widget.lastDate) ? widget.lastDate : today;

      _searchController.clear();
      ref.read(searchTextProvider.notifier).state = '';
      ref.read(dateRangeProvider.notifier).state = DateTimeRange(
        start: validStartDate,
        end: validEndDate,
      );
      ref.read(selectedStationProvider.notifier).state = null; // Réinitialiser la station sélectionnée
      _currentPeriod = dp.DatePeriod(validStartDate, validEndDate);

      // Recentre la carte sur la France avec un zoom fluide
      _animatedMapMove(latlong2.LatLng(47.0, 2.0), 6.0); // Centre de la France avec un zoom par défaut
    });
    _searchFocusNode.requestFocus();
  }

  void _onPeriodChanged(dp.DatePeriod newPeriod) {
    final adjustedStart = newPeriod.start.isAfter(widget.maxSelectableDate)
        ? widget.maxSelectableDate
        : newPeriod.start;
    final adjustedEnd = newPeriod.end.isAfter(widget.maxSelectableDate)
        ? widget.maxSelectableDate
        : newPeriod.end;

    final validStart = adjustedStart.isAfter(adjustedEnd) ? adjustedEnd : adjustedStart;

    setState(() {
      _currentPeriod = dp.DatePeriod(validStart, adjustedEnd);
    });
    ref.read(dateRangeProvider.notifier).state = DateTimeRange(
      start: validStart,
      end: adjustedEnd,
    );
  }

  void _onStationSelected(Map<String, dynamic> selection) async {
    String stationName = selection['libelle_station'] ?? '';
    if (stationName.isEmpty) {
      debugPrint("Nom de la station vide, impossible de récupérer les coordonnées.");
      return;
    }

    // Vérifiez si les coordonnées sont disponibles dans l'objet geometry
    final geometry = selection['geometry'];
    if (geometry != null && geometry['coordinates'] != null) {
      final coordinates = geometry['coordinates'];
      if (coordinates is List && coordinates.length == 2) {
        final longitude = coordinates[0];
        final latitude = coordinates[1];
        debugPrint("Coordonnées de la station sélectionnée :");
        debugPrint("Nom : $stationName");
        debugPrint("Longitude : $longitude");
        debugPrint("Latitude : $latitude");

        // Animation vers la station sur la carte
        _animatedMapMove(latlong2.LatLng(latitude, longitude), 13.0);

        // Mise à jour du provider avec les coordonnées obtenues
        ref.read(selectedStationProvider.notifier).state = {
          ...selection,
          'latitude': latitude,
          'longitude': longitude,
        };
        return;
      }
    }

    debugPrint("Impossible de récupérer les coordonnées pour la station : $stationName");
  }

  void _animatedMapMove(latlong2.LatLng dest, double destZoom) {
    final currentZoom = _mapController.zoom;
    final latTween = Tween<double>(
      begin: _mapController.center.latitude,
      end: dest.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.center.longitude,
      end: dest.longitude,
    );
    final zoomTween = Tween<double>(
      begin: currentZoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 2000), // Augmenter la durée pour une animation plus lente
      vsync: this,
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut, // Courbe fluide pour un style plus agréable
    );

    controller.addListener(() {
      _mapController.move(
        latlong2.LatLng(
          latTween.evaluate(animation),
          lngTween.evaluate(animation),
        ),
        zoomTween.evaluate(animation),
      );
    });

    controller.forward().then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final stationSuggestionsAsync = ref.watch(stationSuggestionsProvider);
    final selectedStation = ref.watch(selectedStationProvider);

    // Mise en cache des suggestions
    final stationSuggestions = stationSuggestionsAsync.when(
      data: (stations) => stations.cast<Map<String, dynamic>>(),
      loading: () => <Map<String, dynamic>>[],
      error: (_, __) => <Map<String, dynamic>>[],
    );

    // Récupérer les coordonnées de la station sélectionnée
    latlong2.LatLng? selectedStationCoordinates;
    if (selectedStation != null &&
        selectedStation['latitude'] != null &&
        selectedStation['longitude'] != null) {
      selectedStationCoordinates = latlong2.LatLng(
        selectedStation['latitude'],
        selectedStation['longitude'],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar and reset button
          Row(
            children: [
              Expanded(
                child: RawAutocomplete<Map<String, dynamic>>(
                  textEditingController: _searchController,
                  focusNode: _searchFocusNode,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final query = textEditingValue.text.trim().toLowerCase();
                    if (query.isEmpty) {
                      return stationSuggestions;
                    }
                    return stationSuggestions.where((station) {
                      final stationName = (station['libelle_station'] ?? '').toLowerCase();
                      return stationName.contains(query) || _isSimilar(stationName, query);
                    });
                  },
                  displayStringForOption: displayStringForOption,
                  onSelected: (Map<String, dynamic> selection) {
                    _onStationSelected(selection);
                    FocusScope.of(context).unfocus();
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextField(
                      key: _fieldKey,
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Rechercher une station',
                        hintText: 'Saisissez le nom d\'une station',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      onChanged: (query) {
                        ref.read(searchTextProvider.notifier).state = query.trim();
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    final RenderBox? renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
                    final double fieldWidth = renderBox?.size.width ?? 0;
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withOpacity(1),
                        child: Container(
                          width: fieldWidth,
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: options.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    "Aucune station trouvée",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    final libelle = option['libelle_station'] ?? '';
                                    final code = option['code_station'] ?? '';
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        "$libelle ($code)",
                                        style: const TextStyle(color: Colors.black),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _resetFilters, // Fusion de la logique de réinitialisation
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 21,
                  ),
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Date range picker
          Text(
            "Plage de dates",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
            ),
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: dp.RangePicker(
                selectedPeriod: _currentPeriod,
                onChanged: _onPeriodChanged,
                firstDate: widget.firstDate,
                lastDate: widget.lastDate,
                datePickerStyles: dp.DatePickerRangeStyles(
                  defaultDateTextStyle: const TextStyle(color: Colors.black),
                  selectedPeriodStartTextStyle: const TextStyle(color: Colors.white),
                  selectedPeriodMiddleTextStyle: const TextStyle(color: Colors.white),
                  selectedPeriodStartDecoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  selectedPeriodMiddleDecoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  selectedPeriodLastDecoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  selectedSingleDateDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Map
          Text(
            "Carte des stations hydrométriques",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias, // Ensures content respects rounded corners
              child: FlutterMap(
                mapController: _mapController, // Utilisation du MapController initialisé
                options: MapOptions(
                  center: latlong2.LatLng(47.0, 2.0), // Center of France
                  zoom: 6.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                    subdomains: ['a', 'b', 'c', 'd'],
                  ),
                  MarkerLayer(
                    markers: [
                      // Marqueurs des suggestions
                      ...stationSuggestions
                          .where((station) =>
                              station['latitude'] != null && station['longitude'] != null)
                          .map((station) {
                        final isSelected = selectedStation?['code_station'] == station['code_station'];
                        return Marker(
                          point: latlong2.LatLng(station['latitude'], station['longitude']),
                          builder: (ctx) => Icon(
                            Icons.location_on,
                            color: isSelected ? Colors.blue[800] : Colors.blue,
                            size: isSelected ? 36.0 : 30.0,
                          ),
                        );
                      }).toList(),

                      // Marqueur bleu pour la station sélectionnée
                      if (selectedStationCoordinates != null)
                        Marker(
                          point: selectedStationCoordinates,
                          builder: (ctx) => const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 40.0,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String displayStringForOption(Map<String, dynamic> option) {
  final libelle = option['libelle_station'] ?? '';
  final code = option['code_station'] ?? '';
  return "$libelle ($code)";
}

/// Fonction pour vérifier si deux chaînes sont similaires (tolérance aux fautes de frappe)
bool _isSimilar(String stationName, String searchText) {
  int distance = _levenshteinDistance(stationName, searchText);
  return distance <= 2;
}

/// Calcul de la distance de Levenshtein (nombre minimal d'opérations nécessaires pour transformer une chaîne en une autre)
int _levenshteinDistance(String s1, String s2) {
  final len1 = s1.length;
  final len2 = s2.length;
  final dp = List.generate(len1 + 1, (_) => List<int>.filled(len2 + 1, 0));

  for (int i = 0; i <= len1; i++) {
    for (int j = 0; j <= len2; j++) {
      if (i == 0) {
        dp[i][j] = j;
      } else if (j == 0) {
        dp[i][j] = i;
      } else if (s1[i - 1] == s2[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] = 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce((a, b) => a < b ? a : b);
      }
    }
  }
  return dp[len1][len2];
}
