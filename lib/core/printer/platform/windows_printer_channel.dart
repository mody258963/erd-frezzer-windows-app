import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../models/printer_device.dart';

class WindowsPrinterChannel {
  WindowsPrinterChannel({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.frostparts/printer');

  final MethodChannel _channel;
  final _log = Logger('WindowsPrinterChannel');

  Future<List<PrinterDevice>> discoverPrinters() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('discoverPrinters');
      final list = result ?? [];
      return list
          .whereType<Map>()
          .map((e) => PrinterDevice.fromMap(Map<dynamic, dynamic>.from(e)))
          .toList();
    } on PlatformException catch (e, st) {
      _log.severe('discoverPrinters failed', e, st);
      rethrow;
    }
  }

  Future<bool> connectPrinter(String printerId, String connectionType) async {
    final result = await _channel.invokeMethod<bool>('connectPrinter', {
      'printerId': printerId,
      'connectionType': connectionType,
    });
    return result ?? false;
  }

  Future<bool> disconnectPrinter(String printerId) async {
    final result = await _channel.invokeMethod<bool>('disconnectPrinter', {
      'printerId': printerId,
    });
    return result ?? false;
  }

  Future<bool> isConnected(String printerId) async {
    final result = await _channel.invokeMethod<bool>('isConnected', {
      'printerId': printerId,
    });
    return result ?? false;
  }

  Future<String> getPrinterStatus(String printerId) async {
    final result = await _channel.invokeMethod<String>('getPrinterStatus', {
      'printerId': printerId,
    });
    return result ?? 'unknown';
  }

  Future<bool> printRaw(List<int> bytes, String printerId) async {
    final result = await _channel.invokeMethod<bool>('printRaw', {
      'printerId': printerId,
      'bytes': bytes,
    });
    return result ?? false;
  }
}
