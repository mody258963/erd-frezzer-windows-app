enum PrinterConnectionType {
  windows('windows'),
  usb('usb'),
  bluetooth('bluetooth');

  const PrinterConnectionType(this.value);
  final String value;

  static PrinterConnectionType fromString(String? raw) {
    return PrinterConnectionType.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => PrinterConnectionType.windows,
    );
  }
}
