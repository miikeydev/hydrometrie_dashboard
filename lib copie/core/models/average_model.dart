class Average {
  final double value;
  Average(this.value);
  factory Average.fromJson(Map<String, dynamic> json) {
    return Average(json['moyenne'] ?? 0);
  }
}
