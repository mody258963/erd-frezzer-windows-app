import 'package:logging/logging.dart';

import '../models/printer_device.dart';
import '../models/printer_settings.dart';
import '../repository/printer_repository.dart';
import 'printer_service.dart';

class PrinterManager {
  PrinterManager(this._repository, this._service);

  final PrinterRepository _repository;
  final PrinterService _service;
  final _log = Logger('PrinterManager');

  List<PrinterDevice> get devices => _repository.cachedDevices;

  PrinterDevice? get connectedPrinter => _service.connectedPrinter;

  PrinterSettings get settings => _repository.loadSettings();

  Future<List<PrinterDevice>> discoverPrinters() async {
    return _repository.discoverPrinters();
  }

  Future<PrinterDevice> connectPrinter(PrinterDevice device) =>
      _service.connectPrinter(device);

  Future<void> disconnectPrinter() => _service.disconnectPrinter();

  Future<PrinterDevice?> reconnectIfConfigured() async {
    await discoverPrinters();
    final settings = _repository.loadSettings();
    if (settings.selectedPrinterId == null) {
      _log.info('No default printer configured');
      return null;
    }
    return _service.reconnectPrinter();
  }

  Future<void> saveSettings(PrinterSettings settings) =>
      _repository.saveSettings(settings);

  Future<PrinterDevice> selectAndConnect(PrinterDevice device) async {
    final settings = _repository.loadSettings().copyWith(
          selectedPrinterId: device.printerId,
        );
    await _repository.saveSettings(settings);
    return connectPrinter(device);
  }
}
