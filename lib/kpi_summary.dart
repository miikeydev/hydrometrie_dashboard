import 'package:flutter/material.dart';

/// Un widget qui affiche un résumé des principaux KPIs pour le débit et la hauteur
class KPISummary extends StatelessWidget {
  final Map<String, dynamic> debitData;
  final Map<String, dynamic> hauteurData;

  const KPISummary({
    Key? key,
    required this.debitData,
    required this.hauteurData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Métriques principales",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                // KPI de débit
                Expanded(
                  child: _buildKPIPanel(
                    debitData['titre'],
                    debitData['moyenne'],
                    debitData['min'],
                    debitData['max'],
                    debitData['unite'],
                    Colors.blue[700]!,
                  ),
                ),
                const SizedBox(width: 12),
                // KPI de hauteur
                Expanded(
                  child: _buildKPIPanel(
                    hauteurData['titre'],
                    hauteurData['moyenne'],
                    hauteurData['min'],
                    hauteurData['max'],
                    hauteurData['unite'],
                    Colors.blue[400]!,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIPanel(
    String title,
    double average,
    String min,
    String max,
    String unit,
    Color color,
  ) {
    String averageText = average > 0 
        ? _formatValue(average, unit) 
        : 'N/A';
    
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          
          // Moyenne
          Row(
            children: [
              Text(
                'Moy:',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  averageText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          
          // Min/Max
          Row(
            children: [
              Text(
                'Min/Max:',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$min / $max',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper pour formater les valeurs numériques
  String _formatValue(double value, String unit) {
    if (value.isNaN || value.isInfinite) {
      return "N/A";
    }
    
    String formattedValue;
    if (value >= 1000000) {
      formattedValue = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      formattedValue = '${(value / 1000).toStringAsFixed(1)}k';
    } else if (value >= 100) {
      formattedValue = value.toStringAsFixed(0);
    } else if (value >= 10) {
      formattedValue = value.toStringAsFixed(1);
    } else {
      formattedValue = value.toStringAsFixed(2);
    }
    
    return '$formattedValue $unit';
  }
}