import 'dart:ui' as ui;

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

/// Renders Unicode (e.g. Arabic) receipt lines as bitmaps for thermal printers.
class ReceiptTextRenderer {
  static bool needsRaster(String text) => text.runes.any((c) => c > 0xFF);

  static TextDirection _textDirection(String text) {
    for (final r in text.runes) {
      if ((r >= 0x0600 && r <= 0x06FF) ||
          (r >= 0x0750 && r <= 0x077F) ||
          (r >= 0xFB50 && r <= 0xFDFF) ||
          (r >= 0xFE70 && r <= 0xFEFF)) {
        return TextDirection.rtl;
      }
    }
    return TextDirection.ltr;
  }

  static TextAlign _textAlign(PosAlign align) {
    return switch (align) {
      PosAlign.left => TextAlign.left,
      PosAlign.center => TextAlign.center,
      PosAlign.right => TextAlign.right,
    };
  }

  static double _fontSize(PosStyles styles) {
    var size = 22.0;
    if (styles.height == PosTextSize.size2 || styles.width == PosTextSize.size2) {
      size = 30;
    }
    if (styles.height == PosTextSize.size3 || styles.width == PosTextSize.size3) {
      size = 36;
    }
    return size;
  }

  /// Renders text to a printer-ready bitmap (width = [paperWidthPx], multiple of 8).
  static Future<img.Image?> renderLine({
    required String text,
    required int paperWidthPx,
    PosStyles styles = const PosStyles(),
  }) async {
    if (text.trim().isEmpty) return null;

    final targetWidth = _alignWidth(paperWidthPx);

    await GoogleFonts.pendingFonts([GoogleFonts.cairo()]);

    final align = styles.align;
    final style = GoogleFonts.cairo(
      fontSize: _fontSize(styles),
      fontWeight: styles.bold ? FontWeight.w700 : FontWeight.w500,
      color: Colors.black,
    );

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: _textDirection(text),
      textAlign: _textAlign(align),
      maxLines: 4,
    )..layout(maxWidth: targetWidth.toDouble());

    final height = painter.height.ceil().clamp(1, 512);

    var dx = 0.0;
    if (align == PosAlign.center) {
      dx = (targetWidth - painter.width) / 2;
    } else if (align == PosAlign.right) {
      dx = targetWidth - painter.width;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), height.toDouble()),
      Paint()..color = Colors.white,
    );
    painter.paint(canvas, Offset(dx, 0));

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(targetWidth, height);
    final png = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    uiImage.dispose();

    if (png == null) return null;

    final decoded = img.decodeImage(png.buffer.asUint8List());
    if (decoded == null) return null;

    // Full paper width; avoids esc_pos_utils_plus imageRaster width%8 bug.
    if (decoded.width != targetWidth) {
      return img.copyResize(
        decoded,
        width: targetWidth,
        height: decoded.height,
        interpolation: img.Interpolation.linear,
      );
    }
    return img.Image.from(decoded);
  }

  /// Paper widths are 384/576; ensure width is divisible by 8 for ESC/POS raster.
  static int _alignWidth(int paperWidthPx) {
    if (paperWidthPx % 8 == 0) return paperWidthPx;
    return ((paperWidthPx + 7) ~/ 8) * 8;
  }
}
