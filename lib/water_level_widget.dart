import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

class WaterLevelWidget extends StatefulWidget {
  final double fillPercent;
  final double size;
  final String formattedValue;
  final String percentage;
  final String title;

  const WaterLevelWidget({
    Key? key,
    required this.fillPercent,
    required this.size,
    required this.formattedValue,
    required this.percentage,
    required this.title,
  }) : super(key: key);

  @override
  _WaterLevelWidgetState createState() => _WaterLevelWidgetState();
}

class _WaterLevelWidgetState extends State<WaterLevelWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController1;
  late AnimationController _waveController2;
  late AnimationController _fillAnimationController;
  late Animation<double> _fillAnimation;
  double _prevFillPercent = 0.1; // Augmenté à 0.1 (10%)

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
    
    _fillAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Initialiser l'animation avec la valeur initiale ou 10% par défaut pour les cas sans données
    final targetFill = widget.fillPercent == 0 ? 0.1 : widget.fillPercent;
    _fillAnimation = Tween<double>(begin: _prevFillPercent, end: targetFill).animate(
      CurvedAnimation(
        parent: _fillAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _fillAnimationController.forward();
  }
  
  @override
  void didUpdateWidget(WaterLevelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fillPercent != widget.fillPercent) {
      // Stocker la valeur actuelle comme point de départ
      _prevFillPercent = _fillAnimation.value;
      
      // Créer une nouvelle animation vers la nouvelle cible (au moins 10% pour les cas sans données)
      final targetFill = widget.fillPercent == 0 ? 0.1 : widget.fillPercent;
      _fillAnimation = Tween<double>(begin: _prevFillPercent, end: targetFill).animate(
        CurvedAnimation(
          parent: _fillAnimationController,
          curve: Curves.easeInOut,
        ),
      );
      
      _fillAnimationController.reset();
      _fillAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _waveController1.dispose();
    _waveController2.dispose();
    _fillAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pour les cas sans données, afficher une valeur par défaut
    final bool hasData = widget.formattedValue != 'N/A' && widget.percentage != "--%";
    final String displayValue = hasData ? widget.formattedValue : "-";

    return AnimatedBuilder(
      animation: Listenable.merge([_waveController1, _waveController2, _fillAnimationController]),
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppTheme.getContainerBackgroundColor(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Le CustomPaint pour les vagues avec le titre pour identifier le type
              CustomPaint(
                painter: WaterPainter(
                  fillPercent: _fillAnimation.value,
                  waveValue1: _waveController1.value * 2 * pi,
                  waveValue2: _waveController2.value * 2 * pi,
                  title: widget.title,
                  isDarkMode: Theme.of(context).brightness == Brightness.dark,
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
                    color: AppTheme.getContainerBackgroundColor(context).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                ),
              ),
              
              // Affichage de la valeur formatée à droite (sans le pourcentage)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.getContainerBackgroundColor(context).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasData ? AppTheme.getTextColor(context) : Colors.grey,
                    ),
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
  final String title;
  final bool isDarkMode;

  WaterPainter({
    required this.fillPercent,
    required this.waveValue1,
    required this.waveValue2,
    required this.title,
    required this.isDarkMode,
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
    
    // Couleurs en fonction du type (débit ou hauteur)
    Color mainColor;
    Color lightColor;
    
    if (title.contains("Q")) { // Pour le débit (Q)
      mainColor = const Color.fromARGB(255, 4, 128, 252); // Utilise les couleurs définies dans AppTheme
      lightColor = AppTheme.debitLightColor;
    } else { // Pour la hauteur (H)
      mainColor = AppTheme.hauteurMainColor;
      lightColor = AppTheme.hauteurLightColor;
    }
    
    // Couleurs des vagues avec dégradés adaptés au type
    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          mainColor.withOpacity(0.6),
          mainColor.withOpacity(0.8),
        ],
      ).createShader(rect);

    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lightColor.withOpacity(0.2),
          lightColor.withOpacity(0.4),
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
            title.contains("Q")
                ? mainColor.withOpacity(0.05) // Teinte spécifique pour débit
                : lightColor.withOpacity(0.05), // Teinte spécifique pour hauteur
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
        oldDelegate.waveValue2 != waveValue2 ||
        oldDelegate.title != title;
  }
}
