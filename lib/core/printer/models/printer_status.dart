enum PrinterStatus {
  unknown('unknown'),
  ready('ready'),
  offline('offline'),
  error('error');

  const PrinterStatus(this.value);
  final String value;

  static PrinterStatus fromString(String? raw) {
    return PrinterStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => PrinterStatus.unknown,
    );
  }
}
