import 'package:flutter/material.dart';
import 'package:flutter_date_pickers/flutter_date_pickers.dart' as dp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'dart:developer' as developer;
import 'dart:async';

class StationInfoPanel extends ConsumerStatefulWidget {
  final String initialSearchText;
  final DateTimeRange initialDateRange;
  
  const StationInfoPanel({
    Key? key,
    this.initialSearchText = '',
    required this.initialDateRange,
  }) : super(key: key);

  @override
  ConsumerState<StationInfoPanel> createState() => _StationInfoPanelState();
}

class _StationInfoPanelState extends ConsumerState<StationInfoPanel> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _fieldKey = GlobalKey();
  late dp.DatePeriod _currentPeriod;
  bool _showClearButton = false;
  
  // Debouncer pour réduire les appels API lors de la recherche
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);
  
  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearchText;
    _currentPeriod = dp.DatePeriod(
      widget.initialDateRange.start,
      widget.initialDateRange.end,
    );
    // Afficher le bouton d'effacement si le texte n'est pas vide
    _showClearButton = _searchController.text.isNotEmpty;
    
    // Ajouter un listener pour détecter les changements de texte
    _searchController.addListener(() {
      setState(() {
        _showClearButton = _searchController.text.isNotEmpty;
      });
    });
    
    // Retarder la modification du provider après le build initial.
    Future.microtask(() {
      ref.read(dateRangeProvider.notifier).state = widget.initialDateRange;
      ref.read(searchTextProvider.notifier).state = widget.initialSearchText;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  void _onSearchChanged(String query) {
    // Annuler le timer précédent s'il existe
    _debounceTimer?.cancel();
    
    // Mettre en place un nouveau timer pour retarder la recherche
    _debounceTimer = Timer(_debounceDuration, () {
      // Ne mettre à jour le provider que si le texte a changé
      if (ref.read(searchTextProvider) != query) {
        ref.read(searchTextProvider.notifier).state = query;
      }
    });
  }
  
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      ref.read(searchTextProvider.notifier).state = '';
      // Optional: Focus le champ pour permettre une nouvelle saisie immédiate
      _searchFocusNode.requestFocus();
    });
  }
  
  void _onPeriodChanged(dp.DatePeriod newPeriod) {
    setState(() {
      _currentPeriod = newPeriod;
    });
    final newRange = DateTimeRange(start: newPeriod.start, end: newPeriod.end);
    ref.read(dateRangeProvider.notifier).state = newRange;
  }
  
  void _resetSelectedStation() {
    ref.read(selectedStationProvider.notifier).state = null;
    _clearSearch();
  }
  
  @override
  Widget build(BuildContext context) {
    // Récupère les suggestions de stations depuis le provider
    final stationSuggestionsAsync = ref.watch(stationSuggestionsProvider);
    final selectedStation = ref.watch(selectedStationProvider);
    
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
          // Barre de recherche avec autocomplete basé sur les résultats API
          RawAutocomplete<Map<String, dynamic>>(
            textEditingController: _searchController,
            focusNode: _searchFocusNode,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Map<String, dynamic>>.empty();
              }
              
              // Utilisation directe du texte au lieu d'attendre le provider pour plus de réactivité
              return stationSuggestionsAsync.when(
                data: (stations) => stations.where((station) {
                  final stationName = (station['libelle_station'] ?? '').toLowerCase();
                  final searchText = textEditingValue.text.toLowerCase();
                  // Recherche plus rapide avec contains au lieu d'attendre le provider
                  return stationName.contains(searchText);
                }),
                loading: () => const [],
                error: (_, __) => const [],
              );
            },
            displayStringForOption: displayStringForOption,
            onSelected: (Map<String, dynamic> selection) {
              _searchController.text = displayStringForOption(selection);
              developer.log('Station sélectionnée: ${selection['libelle_station']} (${selection['code_station']})', 
                  name: 'station_selection');
              developer.log('Détails de la station: $selection', name: 'station_selection');
              ref.read(selectedStationProvider.notifier).state = selection;
              
              // Cacher le clavier après la sélection
              FocusScope.of(context).unfocus();
            },
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              return Container(
                key: _fieldKey,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: InputDecoration(
                    labelText: 'Rechercher une station',
                    hintText: 'Saisissez le nom d\'une station',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _showClearButton 
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
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
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              double fieldWidth = 200;
              final RenderBox? renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                fieldWidth = renderBox.size.width;
              }
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: fieldWidth, maxHeight: 300),
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
          
          // Bouton de réinitialisation si une station est sélectionnée
          if (selectedStation != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton.icon(
                onPressed: _resetSelectedStation,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Réinitialiser la sélection'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            
          const SizedBox(height: 16),
          
          // Titre du sélecteur de date
          Text(
            "Plage de dates",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
            
          const SizedBox(height: 8),
            
          // Sélecteur de dates (calendrier inline)
          Expanded(
            child: Center(
              child: Container(
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
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
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
            ),
          ),
        ],
      ),
    );
  }
  
  String displayStringForOption(Map<String, dynamic> option) {
    final libelle = option['libelle_station'] ?? '';
    final code = option['code_station'] ?? '';
    return "$libelle ($code)";
  }
}
