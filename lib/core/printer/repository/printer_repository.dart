import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/printer_device.dart';
import '../models/printer_settings.dart';
import '../platform/windows_printer_channel.dart';

class PrinterRepository {
  PrinterRepository(this._prefs, this._channel);

  static const _settingsKey = 'printer_settings_json';
  static const _lastPrinterKey = 'last_connected_printer_json';

  final SharedPreferences _prefs;
  final WindowsPrinterChannel _channel;
  final _log = Logger('PrinterRepository');

  List<PrinterDevice> _cached = [];

  List<PrinterDevice> get cachedDevices => List.unmodifiable(_cached);

  Future<List<PrinterDevice>> discoverPrinters() async {
    _log.info('Discovering printers…');
    _cached = await _channel.discoverPrinters();
    _log.info('Found ${_cached.length} printer(s)');
    return _cached;
  }

  PrinterSettings loadSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return const PrinterSettings();
    try {
      return PrinterSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      _log.warning('Failed to parse printer settings', e);
      return const PrinterSettings();
    }
  }

  Future<void> saveSettings(PrinterSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  PrinterDevice? loadLastConnected() {
    final raw = _prefs.getString(_lastPrinterKey);
    if (raw == null) return null;
    try {
      return PrinterDevice.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastConnected(PrinterDevice device) async {
    await _prefs.setString(_lastPrinterKey, jsonEncode(device.toJson()));
  }

  Future<void> clearLastConnected() async {
    await _prefs.remove(_lastPrinterKey);
  }

  WindowsPrinterChannel get channel => _channel;
}
