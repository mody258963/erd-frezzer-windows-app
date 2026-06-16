/// Units that allow decimal quantities per API (June 2026).
const fractionalSaleUnits = {'m', 'kg', 'l'};

bool isFractionalSaleUnit(String? unit) {
  if (unit == null || unit.isEmpty) return false;
  return fractionalSaleUnits.contains(unit.trim().toLowerCase());
}

double saleQuantityStep(String? unit) =>
    isFractionalSaleUnit(unit) ? 0.25 : 1;

double defaultSaleQuantity(String? unit) =>
    isFractionalSaleUnit(unit) ? 0.25 : 1;

double normalizeSaleQuantity(double qty, String? unit) {
  if (qty <= 0) return 0;
  if (!isFractionalSaleUnit(unit)) {
    return qty.roundToDouble().clamp(1, double.infinity);
  }
  return (qty * 10000).roundToDouble() / 10000;
}

bool isSaleQuantityTooLow(double qty, String? unit) {
  if (isFractionalSaleUnit(unit)) return qty < 0.0001;
  return qty < 1;
}

bool hasEnoughStock(double requested, double available) =>
    requested <= available + 1e-9;

/// Signed quantity change (inventory adjust) — preserves sign.
double normalizeQuantityDelta(double delta, String? unit) {
  if (delta == 0) return 0;
  if (!isFractionalSaleUnit(unit)) {
    final rounded = delta.roundToDouble();
    if (rounded == 0) return delta > 0 ? 1 : -1;
    return rounded;
  }
  final sign = delta < 0 ? -1.0 : 1.0;
  final abs = (delta.abs() * 10000).roundToDouble() / 10000;
  return sign * abs;
}

String formatSaleQuantity(double qty, {String? unit}) {
  if (isFractionalSaleUnit(unit)) {
    final rounded = (qty * 10000).roundToDouble() / 10000;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
  return qty.round().toString();
}

/// Suffix for quantity fields — prefer API `unit_label`, else unit code.
String quantityUnitSuffix({String? unit, String? unitLabel}) {
  if (unitLabel != null && unitLabel.trim().isNotEmpty) {
    return unitLabel.trim();
  }
  if (unit != null && unit.trim().isNotEmpty) {
    return unit.trim();
  }
  return '';
}
