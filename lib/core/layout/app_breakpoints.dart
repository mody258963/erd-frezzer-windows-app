import 'dart:ui';

/// Layout breakpoints tuned for ~22 cm × 44 cm portrait POS displays.
class AppBreakpoints {
  AppBreakpoints._();

  /// Shell switches to icon-only nav rail (~72 px).
  static const double narrowWidth = 900;

  /// POS uses stacked tabs instead of side-by-side panels.
  static const double compactWidth = 1024;
  static const double compactHeight = 720;

  /// Ultra-dense POS chrome for narrow cashier displays.
  static const double posDisplayWidth = 720;

  static bool isNarrow(Size size) => size.width < narrowWidth;

  static bool isCompact(Size size) =>
      size.width < compactWidth || size.height < compactHeight;

  static bool isPosDisplay(Size size) => size.width < posDisplayWidth;
}
