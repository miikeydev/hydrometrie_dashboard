import 'package:flutter/material.dart';
import 'package:flutter_date_pickers/flutter_date_pickers.dart' as dp;

/// Barre de filtre contenant uniquement :
///  - Un champ de recherche (avec auto-complétion).
///  - Un sélecteur de dates (inline).
///
/// Le but est de pouvoir, plus tard, gérer ces 2 états (le texte recherché et
/// la plage de dates) via Riverpod et appeler l’API en conséquence.
class StationInfoPanel extends StatefulWidget {
  final String initialSearchText;
  final List<String> stationSuggestions;
  final ValueChanged<String>? onSearchSelected;

  final DateTimeRange initialDateRange;
  final ValueChanged<DateTimeRange>? onDateRangeChanged;

  const StationInfoPanel({
    Key? key,
    this.initialSearchText = '',
    this.stationSuggestions = const [],
    this.onSearchSelected,
    required this.initialDateRange,
    this.onDateRangeChanged,
  }) : super(key: key);

  @override
  State<StationInfoPanel> createState() => _StationInfoPanelState();
}

class _StationInfoPanelState extends State<StationInfoPanel> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _fieldKey = GlobalKey();

  // Liste filtrée pour l'autocomplete
  List<String> _filteredSuggestions = [];

  // Gestion de la plage de dates sélectionnée
  late DateTimeRange _selectedDateRange;
  late dp.DatePeriod _currentPeriod;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearchText;
    _filteredSuggestions = widget.stationSuggestions;

    // Initialisation des dates
    _selectedDateRange = widget.initialDateRange;
    _currentPeriod = dp.DatePeriod(
      widget.initialDateRange.start,
      widget.initialDateRange.end,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredSuggestions = widget.stationSuggestions
          .where(
            (station) => station.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  // Callback appelé lorsqu’on change la plage sur le calendrier
  void _onPeriodChanged(dp.DatePeriod newPeriod) {
    setState(() {
      _currentPeriod = newPeriod;
      _selectedDateRange = DateTimeRange(start: newPeriod.start, end: newPeriod.end);
    });

    if (widget.onDateRangeChanged != null) {
      widget.onDateRangeChanged!(_selectedDateRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// =======================
          /// 1) Barre de recherche
          /// =======================
          RawAutocomplete<String>(
            textEditingController: _searchController,
            focusNode: FocusNode(),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return widget.stationSuggestions.where((option) {
                return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
              });
            },
            onSelected: (String selection) {
              _searchController.text = selection;
              if (widget.onSearchSelected != null) {
                widget.onSearchSelected!(selection);
              }
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
              // Récupère la largeur du champ pour ajuster celle du menu
              double fieldWidth = 200; // fallback
              final RenderBox? renderBox =
                  _fieldKey.currentContext?.findRenderObject() as RenderBox?;
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
                    constraints: BoxConstraints(
                      maxWidth: fieldWidth,
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(
                            option,
                            style: const TextStyle(color: Colors.black),
                          ),
                          onTap: () => onSelected(option),
                          hoverColor: Colors.blue.withOpacity(0.2),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

      

          /// ========================================
          /// 2) Sélecteur de dates (calendrier inline)
          /// ========================================
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
}
