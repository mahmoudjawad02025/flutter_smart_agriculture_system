class SensorUnits {
  SensorUnits._();

  static const String celsius = '°C';
  static const String percent = '%';
  static const String mgPerKg = 'ملغ/كغ';
  static const String milliliter = 'مل';
  static const String milliliterPerSecond = 'مل/ث';

  static String formatValue(
    String? value, {
    required String unit,
    String fallback = '-',
    int fractionDigits = 1,
  }) {
    if (value == null || value.isEmpty || value == '-') {
      return fallback;
    }
    try {
      final double number = double.parse(value);
      final String formatted = number.toStringAsFixed(fractionDigits);
      return attachUnit(formatted, unit);
    } catch (_) {
      return fallback;
    }
  }

  static String attachUnit(String value, String unit) {
    if (value == '-') return value;
    switch (unit) {
      case percent:
      case celsius:
        return '$value$unit';
      default:
        return '$value $unit';
    }
  }

  static String rangeLabel(int min, int max, String unit) {
    return 'الحد الأدنى: ${attachUnit('$min', unit)}  •  الحد الأقصى: ${attachUnit('$max', unit)}';
  }
}
