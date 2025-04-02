import 'package:flutter/material.dart';
import 'package:hydrometrie_dashboard/core/services/hydrometrie_service.dart';

class AverageGauge extends StatefulWidget {
  const AverageGauge({super.key});

  @override
  State<AverageGauge> createState() => _AverageGaugeState();
}

class _AverageGaugeState extends State<AverageGauge> {
  final _service = HydrometrieService();
  double? value;

  @override
  void initState() {
    super.initState();
    _service.fetchAverageFlow().then((res) {
      setState(() {
        value = res;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return const CircularProgressIndicator();
    }
    final percentage = value! / 100;
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percentage.clamp(0, 1),
            strokeWidth: 12,
          ),
          Text('${value!.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}
