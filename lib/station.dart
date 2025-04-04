import 'package:flutter/material.dart';
import 'package:flutter_date_pickers/flutter_date_pickers.dart' as dp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';

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
  final GlobalKey _fieldKey = GlobalKey();
  late dp.DatePeriod _currentPeriod;
  
  @override
void initState() {
  super.initState();
  _searchController.text = widget.initialSearchText;
  _currentPeriod = dp.DatePeriod(
    widget.initialDateRange.start,
    widget.initialDateRange.end,
  );
  // Retarder la modification du provider après le build initial.
  Future.microtask(() {
    ref.read(dateRangeProvider.notifier).state = widget.initialDateRange;
    ref.read(searchTextProvider.notifier).state = widget.initialSearchText;
  });
}

  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged(String query) {
    ref.read(searchTextProvider.notifier).state = query;
  }
  
  void _onPeriodChanged(dp.DatePeriod newPeriod) {
    setState(() {
      _currentPeriod = newPeriod;
    });
    final newRange = DateTimeRange(start: newPeriod.start, end: newPeriod.end);
    ref.read(dateRangeProvider.notifier).state = newRange;
  }
  
  @override
  Widget build(BuildContext context) {
    // Récupère les suggestions de stations depuis le provider
    final stationSuggestionsAsync = ref.watch(stationSuggestionsProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de recherche avec autocomplete basé sur les résultats API
          RawAutocomplete<Map<String, dynamic>>(
            textEditingController: _searchController,
            focusNode: FocusNode(),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Map<String, dynamic>>.empty();
              }
              return stationSuggestionsAsync.when(
                data: (stations) => stations,
                loading: () => const [],
                error: (_, __) => const [],
              );
            },
            displayStringForOption: (option) {
              final libelle = option['libelle_station'] ?? '';
              final code = option['code_station'] ?? '';
              return "$libelle ($code)";
            },
            onSelected: (Map<String, dynamic> selection) {
              _searchController.text = displayStringForOption(selection);
              ref.read(selectedStationProvider.notifier).state = selection;
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
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: _onSearchChanged,
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
                    constraints: BoxConstraints(maxWidth: fieldWidth),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        final libelle = option['libelle_station'] ?? '';
                        final code = option['code_station'] ?? '';
                        return ListTile(
                          title: Text("$libelle ($code)", style: const TextStyle(color: Colors.black)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
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
