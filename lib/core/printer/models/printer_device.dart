import 'printer_connection_type.dart';
import 'printer_status.dart';

class PrinterDevice {
  const PrinterDevice({
    required this.printerName,
    required this.printerId,
    required this.connectionType,
    this.isConnected = false,
    this.printerStatus = PrinterStatus.unknown,
    this.paperWidth = 58,
    this.deviceAddress,
  });

  final String printerName;
  final String printerId;
  final PrinterConnectionType connectionType;
  final bool isConnected;
  final PrinterStatus printerStatus;
  final int paperWidth;
  final String? deviceAddress;

  PrinterDevice copyWith({
    String? printerName,
    String? printerId,
    PrinterConnectionType? connectionType,
    bool? isConnected,
    PrinterStatus? printerStatus,
    int? paperWidth,
    String? deviceAddress,
  }) {
    return PrinterDevice(
      printerName: printerName ?? this.printerName,
      printerId: printerId ?? this.printerId,
      connectionType: connectionType ?? this.connectionType,
      isConnected: isConnected ?? this.isConnected,
      printerStatus: printerStatus ?? this.printerStatus,
      paperWidth: paperWidth ?? this.paperWidth,
      deviceAddress: deviceAddress ?? this.deviceAddress,
    );
  }

  Map<String, dynamic> toJson() => {
        'printerName': printerName,
        'printerId': printerId,
        'connectionType': connectionType.value,
        'isConnected': isConnected,
        'printerStatus': printerStatus.value,
        'paperWidth': paperWidth,
        'deviceAddress': deviceAddress,
      };

  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    return PrinterDevice(
      printerName: json['printerName'] as String? ?? '',
      printerId: json['printerId'] as String? ?? '',
      connectionType:
          PrinterConnectionType.fromString(json['connectionType'] as String?),
      isConnected: json['isConnected'] as bool? ?? false,
      printerStatus:
          PrinterStatus.fromString(json['printerStatus'] as String?),
      paperWidth: json['paperWidth'] as int? ?? 58,
      deviceAddress: json['deviceAddress'] as String?,
    );
  }

  factory PrinterDevice.fromMap(Map<dynamic, dynamic> map) {
    return PrinterDevice(
      printerName: map['printerName']?.toString() ?? '',
      printerId: map['printerId']?.toString() ?? '',
      connectionType: PrinterConnectionType.fromString(
        map['connectionType']?.toString(),
      ),
      isConnected: map['isConnected'] == true,
      printerStatus:
          PrinterStatus.fromString(map['printerStatus']?.toString()),
      paperWidth: int.tryParse(map['paperWidth']?.toString() ?? '') ?? 58,
      deviceAddress: map['deviceAddress']?.toString(),
    );
  }
}
