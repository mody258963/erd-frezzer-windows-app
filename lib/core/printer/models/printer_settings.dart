class PrinterSettings {
  /// Default shop phone printed on receipts.
  static const defaultPhone = '01115298888';

  /// Footer line under the phone on receipts.
  static const defaultFooter = 'المبرمج عشماوي تك';

  const PrinterSettings({
    this.selectedPrinterId,
    this.paperWidthMm = 58,
    this.companyName = 'نور الإسلام',
    this.footer = defaultFooter,
    this.phone = defaultPhone,
  });

  final String? selectedPrinterId;
  final int paperWidthMm;
  final String companyName;
  final String footer;
  final String phone;

  PrinterSettings copyWith({
    String? selectedPrinterId,
    int? paperWidthMm,
    String? companyName,
    String? footer,
    String? phone,
  }) {
    return PrinterSettings(
      selectedPrinterId: selectedPrinterId ?? this.selectedPrinterId,
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
      companyName: companyName ?? this.companyName,
      footer: footer ?? this.footer,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() => {
        'selectedPrinterId': selectedPrinterId,
        'paperWidthMm': paperWidthMm,
        'companyName': companyName,
        'footer': footer,
        'phone': phone,
      };

  factory PrinterSettings.fromJson(Map<String, dynamic> json) {
    return PrinterSettings(
      selectedPrinterId: json['selectedPrinterId'] as String?,
      paperWidthMm: json['paperWidthMm'] as int? ?? 58,
      companyName: json['companyName'] as String? ?? 'نور الإسلام',
      footer: _parseFooter(json['footer'] as String?),
      phone: (json['phone'] as String?)?.trim().isNotEmpty == true
          ? json['phone'] as String
          : defaultPhone,
    );
  }

  /// Phone line on receipt (saved setting or [defaultPhone]).
  String get receiptPhone =>
      phone.trim().isNotEmpty ? phone.trim() : defaultPhone;

  /// Footer on receipt (migrates legacy English branding).
  String get receiptFooter {
    final f = footer.trim();
    if (f.isEmpty ||
        f == 'Powered by Ashmawy Tech' ||
        f.toLowerCase() == 'powered by ashmawy tech') {
      return defaultFooter;
    }
    return f;
  }

  static String _parseFooter(String? raw) {
    final f = raw?.trim() ?? '';
    if (f.isEmpty ||
        f == 'Powered by Ashmawy Tech' ||
        f.toLowerCase() == 'powered by ashmawy tech') {
      return defaultFooter;
    }
    return f;
  }
}
