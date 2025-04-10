import 'package:flutter/material.dart';
import 'theme.dart';

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
    // Séparation de la valeur et de l'unité pour un meilleur affichage
    final parts = value.split(' ');
    final numericValue = parts.isNotEmpty ? parts.first : "N/A";
    final unit = parts.length > 1 ? parts.last : "";
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getContainerBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (titre du StatBox)
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[400] 
                  : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          // Zone de valeur avec l'unité en bas à droite
          Expanded(
            child: Stack(
              children: [
                // Valeur principale (centrée)
                Align(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      numericValue,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                  ),
                ),
                
                // Unité (en bas à droite)
                if (unit.isNotEmpty)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[400] 
                            : Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}