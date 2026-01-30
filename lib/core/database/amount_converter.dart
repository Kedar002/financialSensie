/// Amount conversion utilities.
/// Converts between display amounts (double) and storage amounts (int paise).
///
/// Why paise: Avoids floating-point precision errors.
/// Example: ₹1,234.56 → stored as 123456 (paise)
class AmountConverter {
  /// Convert rupees (display) to paise (storage).
  static int toPaise(double rupees) => (rupees * 100).round();

  /// Convert paise (storage) to rupees (display).
  static double toRupees(int paise) => paise / 100.0;
}
