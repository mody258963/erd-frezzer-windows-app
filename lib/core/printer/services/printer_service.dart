import 'package:logging/logging.dart';

import '../models/printer_device.dart';
import '../models/printer_status.dart';
import '../repository/printer_repository.dart';

class PrinterException implements Exception {
  PrinterException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PrinterService {
  PrinterService(this._repository);

  final PrinterRepository _repository;
  final _log = Logger('PrinterService');

  PrinterDevice? _connected;

  PrinterDevice? get connectedPrinter => _connected;

  Future<List<PrinterDevice>> discoverPrinters() => _repository.discoverPrinters();

  Future<PrinterDevice> connectPrinter(PrinterDevice device) async {
    _log.info('Connecting to ${device.printerName}');
    final ok = await _repository.channel.connectPrinter(
      device.printerId,
      device.connectionType.value,
    );
    if (!ok) {
      throw PrinterException('Could not connect to ${device.printerName}');
    }
    final statusRaw =
        await _repository.channel.getPrinterStatus(device.printerId);
    _connected = device.copyWith(
      isConnected: true,
      printerStatus: PrinterStatus.fromString(statusRaw),
    );
    await _repository.saveLastConnected(_connected!);
    return _connected!;
  }

  Future<void> disconnectPrinter() async {
    final device = _connected;
    if (device == null) return;
    _log.info('Disconnecting ${device.printerName}');
    await _repository.channel.disconnectPrinter(device.printerId);
    _connected = device.copyWith(isConnected: false);
    await _repository.clearLastConnected();
    _connected = null;
  }

  Future<PrinterDevice?> reconnectPrinter() async {
    final last = _repository.loadLastConnected();
    if (last == null) return null;
    final settings = _repository.loadSettings();
    final match = _repository.cachedDevices
        .where((d) => d.printerId == (settings.selectedPrinterId ?? last.printerId))
        .firstOrNull;
    final target = match ?? last;
    try {
      return await connectPrinter(target);
    } catch (e, st) {
      _log.warning('Auto-reconnect failed', e, st);
      return null;
    }
  }

  Future<bool> isConnected([String? printerId]) async {
    final id = printerId ?? _connected?.printerId;
    if (id == null) return false;
    return _repository.channel.isConnected(id);
  }

  Future<PrinterStatus> getPrinterStatus([String? printerId]) async {
    final id = printerId ?? _connected?.printerId;
    if (id == null) return PrinterStatus.offline;
    final raw = await _repository.channel.getPrinterStatus(id);
    return PrinterStatus.fromString(raw);
  }

  Future<void> printRaw(List<int> bytes, {String? printerId}) async {
    final id = printerId ?? _connected?.printerId ?? _repository.loadSettings().selectedPrinterId;
    if (id == null || id.isEmpty) {
      throw PrinterException('No printer selected');
    }
    final connected = await isConnected(id);
    if (!connected) {
      throw PrinterException('Printer is not connected');
    }
    if (bytes.isEmpty) {
      throw PrinterException('Nothing to print (empty receipt data)');
    }
    _log.info('Printing ${bytes.length} bytes to $id');
    final ok = await _repository.channel.printRaw(bytes, id);
    if (!ok) {
      throw PrinterException(
        'Print job failed — check printer name, connection, and that it supports RAW ESC/POS',
      );
    }
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
