import 'dart:math';

class HydrometrieService {
  Future<double> fetchAverageFlow() async {
    await Future.delayed(const Duration(seconds: 1));
    return Random().nextDouble() * 100;
  }
}
