/// How the Asr time is derived.
///
/// [standard] (Shafi'i, Maliki, Hanbali): shadow length == object length.
/// [hanafi]: shadow length == 2 × object length (later Asr).
enum AsrCalculationMethod {
  standard,
  hanafi;

  String get key => name;

  static AsrCalculationMethod fromKey(String key) =>
      AsrCalculationMethod.values.firstWhere((e) => e.name == key,
          orElse: () => AsrCalculationMethod.standard);
}
