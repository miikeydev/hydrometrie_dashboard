import 'package:flutter/material.dart';
import 'package:flutter_date_pickers/flutter_date_pickers.dart' as dp;

///
/// A widget that displays:
/// 1) A search box at the top (with autocomplete).
/// 2) Station details (code, address, coordinates).
/// 3) An inline date-range picker (directly on the interface).
///
/// All values are passed in as constructor parameters so they can
/// be easily changed later. Styling is kept simple with white, black and blue colors.
///
class StationInfoPanel extends StatefulWidget {
  final String initialSearchText;
  final List<String> stationSuggestions;
  final ValueChanged<String>? onSearchSelected;

  final String stationCode;
  final String stationAddress;
  final String stationCoordinates;

  final DateTimeRange initialDateRange;
  final ValueChanged<DateTimeRange>? onDateRangeChanged;

  const StationInfoPanel({
    Key? key,
    this.initialSearchText = '',
    this.stationSuggestions = const [],
    this.onSearchSelected,
    required this.stationCode,
    required this.stationAddress,
    required this.stationCoordinates,
    required this.initialDateRange,
    this.onDateRangeChanged,
  }) : super(key: key);

  @override
  State<StationInfoPanel> createState() => _StationInfoPanelState();
}

class _StationInfoPanelState extends State<StationInfoPanel> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredSuggestions = [];

  // GlobalKey to get the width of the search field container
  final GlobalKey _fieldKey = GlobalKey();

  // We'll keep a DateTimeRange for outside use
  late DateTimeRange _selectedDateRange;

  // Flutter Date Pickers uses dp.DatePeriod for "start" and "end"
  late dp.DatePeriod _currentPeriod;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearchText;
    _filteredSuggestions = widget.stationSuggestions;

    _selectedDateRange = widget.initialDateRange;
    // Convert the incoming DateTimeRange to dp.DatePeriod
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
          .where((station) => station.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // When the user changes the period on the inline calendar,
  // update our DateTimeRange and call the callback if any.
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
    final dateRangeText =
        '${_formatDate(_selectedDateRange.start)} — ${_formatDate(_selectedDateRange.end)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* ======= Search Box with Floating Dropdown ======= */
          RawAutocomplete<String>(
            textEditingController: _searchController,
            focusNode: FocusNode(),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return widget.stationSuggestions.where((String option) {
                return option
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              _searchController.text = selection;
              if (widget.onSearchSelected != null) {
                widget.onSearchSelected!(selection);
              }
            },
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              // Wrap the TextField in a Container with a GlobalKey to capture its width.
              return Container(
                key: _fieldKey,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: InputDecoration(
                    labelText: 'Search or code station',
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
              // Retrieve the width of the search field
              double fieldWidth = 200; // default fallback
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
                  color: Colors.white, // white background from theme
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

          const SizedBox(height: 16),
          /* ======= Station Info ======= */
          Text(
            'Code station',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(widget.stationCode, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),

          Text(
            'Adresse',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(widget.stationAddress, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),

          Text(
            'Coordonnées',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(widget.stationCoordinates, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),

          /* ======= Inline Date Range Picker ======= */
          Text(
            'Dates',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Current range displayed as text
          Text(dateRangeText, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 32),

          // Inline Range Picker
          Expanded(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                ),
                padding: const EdgeInsets.all(8),
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

  String _formatDate(DateTime date) {
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
  }

  String _pad(int value) {
    return value.toString().padLeft(2, '0');
  }
}
