import 'package:flutter/material.dart';
import 'package:flutter_date_pickers/flutter_date_pickers.dart' as dp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'dart:async';
import 'dart:developer' as developer;
import 'theme.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

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
  final MapController _mapController = MapController();
  late dp.DatePeriod _currentPeriod;
  Timer? _searchDebounce;
  late Key _calendarKey;

  late DateTime _today;
  late final DateTime _min;
  late final DateTime _max;

  /// Variable pour stocker la clé de suggestion précédente
  String _lastSuggestionsKey = '';

  @override
  void initState() {
    super.initState();
    _today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _min = _today.subtract(const Duration(days: 30));
    _max = _today;
    final defaultStart = _today.subtract(const Duration(days: 6));
    final defaultEnd = _today;
    _currentPeriod = dp.DatePeriod(defaultStart, defaultEnd);
    _calendarKey = ValueKey('${defaultStart.toIso8601String()}_${defaultEnd.toIso8601String()}');
    _searchController.text = widget.initialSearchText;

    // Listener avec debounce pour effectuer une requête API
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        ref.read(searchTextProvider.notifier).state = query;
      });
    });

    Future.microtask(() {
      ref.read(dateRangeProvider.notifier).state = DateTimeRange(
        start: defaultStart,
        end: defaultEnd,
      );
      ref.read(searchTextProvider.notifier).state = widget.initialSearchText;

      // Charger la carte sur la France entière au départ
      _animatedMapMove(latlong2.LatLng(47.0, 2.0), 5);
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
    FocusScope.of(context).unfocus();
    setState(() {
      _searchController.clear();
      ref.read(searchTextProvider.notifier).state = '';
      
      // Réinitialiser à la date actuelle pour assurer le bon affichage du mois courant
      _today = DateTime.now();
      final defaultStart = _today.subtract(const Duration(days: 6));
      final defaultEnd = _today;
      
      ref.read(dateRangeProvider.notifier).state = DateTimeRange(
        start: defaultStart,
        end: defaultEnd,
      );
      ref.read(selectedStationProvider.notifier).state = null;
      _currentPeriod = dp.DatePeriod(defaultStart, defaultEnd);
      
      // Forcer la régénération du calendrier avec une nouvelle clé pour s'assurer qu'il s'affiche correctement
      _calendarKey = ValueKey('reset_${DateTime.now().millisecondsSinceEpoch}');
      
      // Recentrer la carte sur la France
      _animatedMapMove(latlong2.LatLng(47.0, 2.0), 6.0);
    });
    
    // Après avoir réinitialisé, remettre le focus sur la barre de recherche
    _searchFocusNode.requestFocus();
  }

  void _onPeriodChanged(dp.DatePeriod newPeriod) {
    final start = newPeriod.start.isBefore(_min) ? _min : newPeriod.start;
    final end = newPeriod.end.isAfter(_max) ? _max : newPeriod.end;
    setState(() => _currentPeriod = dp.DatePeriod(start, end));
    ref.read(dateRangeProvider.notifier).state = DateTimeRange(start: start, end: end);
  }

  void _onStationSelected(Map<String, dynamic> selection) async {
    String stationName = selection['libelle_station'] ?? '';
    if (stationName.isEmpty) {
      debugPrint("Nom de la station vide, impossible de récupérer les coordonnées.");
      return;
    }

    final geometry = selection['geometry'];
    if (geometry != null && geometry['coordinates'] != null) {
      final coordinates = geometry['coordinates'];
      if (coordinates is List && coordinates.length == 2) {
        final longitude = coordinates[0];
        final latitude = coordinates[1];
        developer.log("Station sélectionnée: $stationName, Latitude: $latitude, Longitude: $longitude", name: 'StationInfoPanel');

        _animatedMapMove(latlong2.LatLng(latitude, longitude), 13.0);

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
      duration: const Duration(milliseconds: 4000), 
      vsync: this,
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
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
    // Récupérer les suggestions depuis le provider Riverpod
    final stationSuggestionsAsync = ref.watch(stationSuggestionsProvider);
    final selectedStation = ref.watch(selectedStationProvider);
    final isDarkMode = ref.watch(darkModeProvider);

    final stationSuggestions = stationSuggestionsAsync.when(
      data: (stations) {
        print("🧭 Suggestions affichées dans l'UI : ${stations.length}");
        return stations.cast<Map<String, dynamic>>();
      },
      loading: () => <Map<String, dynamic>>[],
      error: (_, __) => <Map<String, dynamic>>[],
    );

    // ----- ETAPE 2 : Simuler un changement dans le champ de texte si les suggestions ont changé -----
    // On crée une clé basée sur la liste actuelle des codes de stations.
    String newSuggestionsKey = stationSuggestions.map((e) => e['code_station']).join('-');
    if (_lastSuggestionsKey != newSuggestionsKey) {
      _lastSuggestionsKey = newSuggestionsKey;
      // On simule un léger changement dans le TextEditingController pour forcer le rafraîchissement de l'overlay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentText = _searchController.text;
        _searchController.value = TextEditingValue(
          text: '$currentText ',
    selection: TextSelection.collapsed(offset: currentText.length + 1),
  );
  _searchController.value = TextEditingValue(
    text: currentText,
    selection: TextSelection.collapsed(offset: currentText.length),
    );
     // Retour à la valeur d'origine
      });
    }

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

    // URL de la carte en fonction du mode sombre
    final tileUrl = isDarkMode
        ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        : "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png";

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getContainerBackgroundColor(context).withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar de recherche et bouton de réinitialisation
          Row(
            children: [
              Expanded(
                child: RawAutocomplete<Map<String, dynamic>>(
                  // ----- ETAPE 3 : Utilisation d'une clé dynamique -----
                  key: ValueKey(newSuggestionsKey),
                  textEditingController: _searchController,
                  focusNode: _searchFocusNode,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final query = textEditingValue.text.trim().toLowerCase();
                    print("🔍 UI Query: $query");
                    for (var station in stationSuggestions) {
                      print("💡 Nom station : ${station['libelle_station']?.toString().toLowerCase()}");
                    }
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
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                        hintText: 'Saisissez le nom d\'une station',
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[500]
                              : Colors.grey[400],
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2C2C2C)
                            : Colors.white,
                      ),
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                      ),
                      onChanged: (query) {
                        print("➡️ onChanged triggered: $query");
                        if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
                        _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                          final cleaned = query.trim();
                          print("⏳ Debounce set searchTextProvider: $cleaned");
                          ref.read(searchTextProvider.notifier).state = cleaned;
                        });
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    final RenderBox? renderBox =
                        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
                    final double fieldWidth = renderBox?.size.width ?? 0;
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.getContainerBackgroundColor(context),
                        child: Container(
                          width: fieldWidth,
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: options.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    "Aucune station trouvée",
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark 
                                          ? Colors.grey[400] 
                                          : Colors.grey[600],
                                    ),
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
                                        style: TextStyle(
                                          color: AppTheme.getTextColor(context),
                                        ),
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
                onPressed: _resetFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 21,
                  ),
                ),
                child: Icon(
                  Icons.refresh,
                  color: AppTheme.getIconColor(context),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Date range picker - moderne (Syncfusion)
          Text(
            "Plage de dates",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 300, // double de la taille précédente
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.getContainerBackgroundColor(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SfDateRangePicker(
                key: _calendarKey,
                selectionMode: DateRangePickerSelectionMode.range,
                initialSelectedRange: PickerDateRange(_currentPeriod.start, _currentPeriod.end),
                minDate: _min,
                maxDate: _max,
                onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                  if (args.value is PickerDateRange) {
                    final range = args.value as PickerDateRange;
                    final start = range.startDate ?? _min;
                    final end = range.endDate ?? start;
                    setState(() {
                      _currentPeriod = dp.DatePeriod(start, end);
                      // Ne pas changer la clé ici !
                    });
                    ref.read(dateRangeProvider.notifier).state = DateTimeRange(start: start, end: end);
                  }
                },
                onViewChanged: (DateRangePickerViewChangedArgs args) {
                  // Ne rien faire ici pour permettre la navigation libre
                },
                enablePastDates: true,
                showActionButtons: false,
                view: DateRangePickerView.month,
                
                // Personnalisation des couleurs en fonction du thème
                selectionColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1976D2) // Bleu foncé pour thème sombre
                    : const Color(0xFF2196F3), // Bleu pour thème clair
                
                // Couleur de l'intervalle
                rangeSelectionColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1976D2).withOpacity(0.3) // Bleu foncé avec transparence pour thème sombre
                    : const Color(0xFF2196F3).withOpacity(0.15), // Bleu avec transparence pour thème clair
                
                // Couleurs du début et fin de l'intervalle
                startRangeSelectionColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1976D2) // Bleu foncé pour thème sombre
                    : const Color(0xFF2196F3), // Bleu pour thème clair
                
                endRangeSelectionColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1976D2) // Bleu foncé pour thème sombre
                    : const Color(0xFF2196F3), // Bleu pour thème clair
                
                // Couleur mise en évidence aujourd'hui
                todayHighlightColor: const Color(0xFF1976D2),
                
                // Couleur de fond du calendrier en fonction du thème
                backgroundColor: AppTheme.getContainerBackgroundColor(context),
                
                // Style des jours et des mois
                monthViewSettings: DateRangePickerMonthViewSettings(
                  firstDayOfWeek: 1, // Premier jour = lundi
                  viewHeaderHeight: 35,
                  viewHeaderStyle: DateRangePickerViewHeaderStyle(
                    textStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                  showTrailingAndLeadingDates: true,
                  dayFormat: 'EE', // Format court pour les jours de la semaine
                ),
                
                // Style de l'en-tête du calendrier
                headerStyle: DateRangePickerHeaderStyle(
                  textAlign: TextAlign.center,
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[800],
                  ),
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2C2C2C) // Gris foncé pour thème sombre
                      : Colors.grey[100], // Gris clair pour thème clair
                ),
                
                // Style des dates
                monthCellStyle: DateRangePickerMonthCellStyle(
                  textStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey[700],
                  ),
                  todayTextStyle: TextStyle(
                    color: const Color(0xFF1976D2),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  leadingDatesTextStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white30
                        : Colors.grey[400],
                    fontSize: 12,
                  ),
                  trailingDatesTextStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white30
                        : Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Map - s'agrandit automatiquement
          Text(
            "Carte des stations hydrométriques",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              // Agrandit la map (moins de padding vertical)
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: latlong2.LatLng(47.0, 2.0),
                  zoom: 6.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: tileUrl,
                    subdomains: ['a', 'b', 'c', 'd'],
                  ),
                  MarkerLayer(
                    markers: [
                      ...stationSuggestions
                          .where((station) =>
                              station['latitude'] != null &&
                              station['longitude'] != null)
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

/// Calcul de la distance de Levenshtein
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
