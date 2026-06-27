import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:logging/logging.dart';

import 'receipt_text_renderer.dart';

/// Prints receipt text via ESC/POS, rasterizing lines that contain Arabic/Unicode.
class EscPosTextHelper {
  static final _log = Logger('EscPosTextHelper');

  /// ESC/POS built-in fonts only accept Latin-1. Strip/replace everything else.
  static String sanitizeForEscPos(String text) {
    return text
        .replaceAll('…', '...')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('·', '.')
        .replaceAll(RegExp(r'[^\x00-\xFF]'), '?');
  }

  static bool _needsRaster(String text) =>
      ReceiptTextRenderer.needsRaster(text) ||
      text.contains('…') ||
      text.contains('—') ||
      text.contains('–');

  static String _truncateItem(String item) {
    final safe = sanitizeForEscPos(item);
    if (safe.length <= 14) return safe;
    return '${safe.substring(0, 13)}...';
  }

  static Future<void> printLine(
    Generator generator,
    List<int> bytes,
    String text, {
    PosStyles styles = const PosStyles(),
    required int paperWidthPx,
  }) async {
    if (text.isEmpty) return;

    if (!_needsRaster(text)) {
      bytes.addAll(
        generator.text(sanitizeForEscPos(text), styles: styles),
      );
      return;
    }

    try {
      final raster = await ReceiptTextRenderer.renderLine(
        text: text,
        paperWidthPx: paperWidthPx,
        styles: styles,
      );
      if (raster == null) {
        _printAsciiFallback(generator, bytes, text, styles);
        return;
      }

      bytes.addAll(
        generator.image(
          raster,
          align: styles.align,
        ),
      );
      bytes.addAll(generator.feed(1));
    } catch (e, st) {
      _log.warning('Raster print failed for "$text"', e, st);
      _printAsciiFallback(generator, bytes, text, styles);
    }
  }

  static void _printAsciiFallback(
    Generator generator,
    List<int> bytes,
    String text,
    PosStyles styles,
  ) {
    bytes.addAll(
      generator.text(
        sanitizeForEscPos(text),
        styles: styles,
      ),
    );
  }

  static Future<void> printLabelValueRow(
    Generator generator,
    List<int> bytes, {
    required String label,
    required String value,
    required int paperWidthPx,
    bool bold = false,
  }) async {
    await printColumns(
      generator,
      bytes,
      left: label,
      right: value,
      paperWidthPx: paperWidthPx,
      leftStyles: PosStyles(bold: bold),
      rightStyles: PosStyles(align: PosAlign.right, bold: bold),
    );
  }

  static String _joinTableCells(
    String item,
    String qty,
    String price,
    String total,
  ) {
    String pad(String value, int width) {
      if (value.length >= width) return value;
      return value.padLeft(width);
    }

    return '${pad(qty, 4)} ${pad(price, 8)} ${pad(total, 8)}  $item';
  }

  static void printRow(
    Generator generator,
    List<int> bytes,
    List<PosColumn> columns,
  ) {
    bytes.addAll(
      generator.row(
        columns
            .map(
              (c) => PosColumn(
                text: sanitizeForEscPos(c.text),
                width: c.width,
                styles: c.styles,
              ),
            )
            .toList(),
      ),
    );
  }

  static Future<void> printColumns(
    Generator generator,
    List<int> bytes, {
    required String left,
    required String right,
    required int paperWidthPx,
    PosStyles leftStyles = const PosStyles(),
    PosStyles rightStyles = const PosStyles(align: PosAlign.right),
  }) async {
    if (!_needsRaster(left) && !_needsRaster(right)) {
      printRow(generator, bytes, [
        PosColumn(text: left, width: 8, styles: leftStyles),
        PosColumn(text: right, width: 4, styles: rightStyles),
      ]);
      return;
    }

    final line = _formatTwoColumns(left, right);
    await printLine(
      generator,
      bytes,
      line,
      styles: leftStyles,
      paperWidthPx: paperWidthPx,
    );
  }

  static String _formatTwoColumns(String left, String right) {
    const charsPerLine = 32;
    final pad = charsPerLine - left.length - right.length;
    if (pad > 0) {
      return '$left${' ' * pad}$right';
    }
    return '$left $right';
  }

  /// Receipt table: item | qty | price | total (12-column ESC/POS row).
  static Future<void> printTableRow(
    Generator generator,
    List<int> bytes, {
    required int paperWidthPx,
    required String item,
    required String qty,
    required String price,
    required String total,
    bool bold = false,
  }) async {
    final style = PosStyles(bold: bold);
    final numStyle = PosStyles(align: PosAlign.right, bold: bold);

    final needsImage = _needsRaster(item) ||
        _needsRaster(qty) ||
        _needsRaster(price) ||
        _needsRaster(total);

    if (!needsImage) {
      printRow(generator, bytes, [
        PosColumn(
          text: _truncateItem(item),
          width: 5,
          styles: style,
        ),
        PosColumn(text: qty, width: 2, styles: numStyle),
        PosColumn(text: price, width: 2, styles: numStyle),
        PosColumn(text: total, width: 3, styles: numStyle),
      ]);
      return;
    }

    // Arabic (or mixed) qty/price/total — one raster line for the full row.
    if (_needsRaster(qty) || _needsRaster(price) || _needsRaster(total)) {
      await printLine(
        generator,
        bytes,
        _joinTableCells(item, qty, price, total),
        styles: style,
        paperWidthPx: paperWidthPx,
      );
      return;
    }

    if (_needsRaster(item)) {
      await printLine(
        generator,
        bytes,
        item,
        styles: const PosStyles(align: PosAlign.right),
        paperWidthPx: paperWidthPx,
      );
    } else {
      await printLine(
        generator,
        bytes,
        _truncateItem(item),
        styles: const PosStyles(align: PosAlign.right),
        paperWidthPx: paperWidthPx,
      );
    }
    final qtySafe = sanitizeForEscPos(qty);
    final priceSafe = sanitizeForEscPos(price);
    final totalSafe = sanitizeForEscPos(total);
    await printLine(
      generator,
      bytes,
      '${qtySafe.padLeft(4)} ${priceSafe.padLeft(8)} ${totalSafe.padLeft(8)}',
      styles: const PosStyles(align: PosAlign.center),
      paperWidthPx: paperWidthPx,
    );
  }
}
