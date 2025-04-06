import 'dart:math';
import 'package:flutter/material.dart';

class WaterLevelWidget extends StatefulWidget {
  final double fillPercent; // Valeur entre 0.0 (vide) et 1.0 (plein)
  final double size;
  final String formattedValue; // Valeur formatée (moyenne)
  final String percentage; // Pourcentage à afficher

  const WaterLevelWidget({
    Key? key,
    required this.fillPercent,
    required this.size,
    required this.formattedValue,
    required this.percentage,
  }) : super(key: key);

  @override
  _WaterLevelWidgetState createState() => _WaterLevelWidgetState();
}

class _WaterLevelWidgetState extends State<WaterLevelWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController1;
  late AnimationController _waveController2;

  @override
  void initState() {
    super.initState();
    _waveController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _waveController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController1.dispose();
    _waveController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si le formattedValue est N/A et pourcentage est --%, on affiche "Aucune donnée"
    if (widget.formattedValue == 'N/A' && widget.percentage == "--%") {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "Aucune donnée",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Identifier le type de données pour déterminer le titre
    String title = widget.formattedValue.endsWith("m³/s") ? "Débit" : "Hauteur";

    // Sinon, on affiche le widget d'eau animé
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController1, _waveController2]),
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Le CustomPaint pour les vagues
              CustomPaint(
                painter: WaterPainter(
                  fillPercent: widget.fillPercent,
                  waveValue1: _waveController1.value * 2 * pi,
                  waveValue2: _waveController2.value * 2 * pi,
                ),
                size: Size(widget.size, widget.size),
              ),
              
              // Titre au centre gauche
              Positioned(
                top: 8,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              
              // Affichage de la valeur formatée et du pourcentage à droite
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Valeur formatée (ex: "500k")
                      Text(
                        widget.formattedValue,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Pourcentage (ex: "65%")
                      Text(
                        widget.percentage,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WaterPainter extends CustomPainter {
  final double fillPercent;
  final double waveValue1;
  final double waveValue2;

  WaterPainter({
    required this.fillPercent,
    required this.waveValue1,
    required this.waveValue2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clipRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRRect(
      RRect.fromRectAndRadius(clipRect, const Radius.circular(16)),
    );

    // Hauteur de base en fonction du pourcentage de remplissage
    final baseHeight = size.height * (1 - fillPercent);
    final amplitude = size.height * 0.05;
    final waveLength = size.width;

    // Première vague (sinus)
    final path1 = Path();
    path1.moveTo(0, baseHeight);
    for (double x = 0; x <= size.width; x++) {
      final y = amplitude * sin((2 * pi / waveLength) * x + waveValue1) + baseHeight;
      path1.lineTo(x, y);
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();

    // Deuxième vague (cosinus, légèrement décalée)
    final path2 = Path();
    path2.moveTo(0, baseHeight);
    for (double x = 0; x <= size.width; x++) {
      final y = amplitude * cos((2 * pi / waveLength) * x + waveValue2 + pi / 4) + baseHeight + (amplitude / 2);
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    // Créons un dégradé mesh en superposition
    final rect = Rect.fromLTWH(0, baseHeight, size.width, size.height - baseHeight);
    
    // Couleurs des vagues avec dégradés
    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.withOpacity(0.6),
          Colors.blue.withOpacity(0.8),
        ],
      ).createShader(rect);

    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.withOpacity(0.2),
          Colors.blue.withOpacity(0.4),
        ],
      ).createShader(rect);

    // Dessiner les vagues
    canvas.drawPath(path2, paint2); // Dessiner d'abord la vague plus claire
    canvas.drawPath(path1, paint1); // Puis la vague plus foncée
    
    // Ajouter un mesh gradient en superposition
    if (fillPercent > 0.0) {
      final meshPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.transparent,
            Colors.white.withOpacity(0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
          tileMode: TileMode.mirror,
        ).createShader(rect);
      
      // Dessiner le mesh gradient sur toute la zone d'eau
      canvas.drawRect(rect, meshPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WaterPainter oldDelegate) {
    return oldDelegate.fillPercent != fillPercent ||
        oldDelegate.waveValue1 != waveValue1 ||
        oldDelegate.waveValue2 != waveValue2;
  }
}
