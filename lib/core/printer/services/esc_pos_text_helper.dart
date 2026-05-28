import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:logging/logging.dart';

import 'receipt_text_renderer.dart';

/// Prints receipt text via ESC/POS, rasterizing lines that contain Arabic/Unicode.
class EscPosTextHelper {
  static final _log = Logger('EscPosTextHelper');

  static Future<void> printLine(
    Generator generator,
    List<int> bytes,
    String text, {
    PosStyles styles = const PosStyles(),
    required int paperWidthPx,
  }) async {
    if (text.isEmpty) return;

    if (!ReceiptTextRenderer.needsRaster(text)) {
      bytes.addAll(generator.text(text, styles: styles));
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

      // Use ESC * column image — imageRaster() breaks when width % 8 != 0.
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
        text.replaceAll(RegExp(r'[^\x00-\xFF]'), '?'),
        styles: styles,
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
    if (!ReceiptTextRenderer.needsRaster(left) &&
        !ReceiptTextRenderer.needsRaster(right)) {
      bytes.addAll(generator.row([
        PosColumn(text: left, width: 8, styles: leftStyles),
        PosColumn(text: right, width: 4, styles: rightStyles),
      ]));
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
}
