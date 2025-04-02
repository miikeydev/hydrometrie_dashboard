import 'package:flutter/material.dart';

/// A simple stat box showing:
/// - A label (e.g., "Min débit")
/// - A numeric/string value (e.g., "78 m/s")
///
/// Both values are passed in via constructor so they can
/// be updated or replaced easily. The box includes a
/// rounded corner background with a slight shadow.
class StatBox extends StatelessWidget {
  final String label;
  final String value;

  const StatBox({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120, // or adjust as needed
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
          ),
          const SizedBox(height: 6),
          Text(
            value,
          ),
        ],
      ),
    );
  }
}
