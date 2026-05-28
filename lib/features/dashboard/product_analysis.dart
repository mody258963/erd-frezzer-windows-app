/// Per-product metrics merged from sales report + inventory alerts.
class ProductAnalysisItem {
  const ProductAnalysisItem({
    required this.partId,
    required this.code,
    required this.name,
    required this.quantitySold,
    required this.revenue,
    this.stockQty,
    this.lowStock = false,
  });

  final String partId;
  final String code;
  final String name;
  final int quantitySold;
  final double revenue;
  final int? stockQty;
  final bool lowStock;

  String get displayTitle =>
      code.isNotEmpty && name.isNotEmpty ? '$code — $name' : (name.isNotEmpty ? name : code);
}

List<ProductAnalysisItem> buildProductAnalysis({
  required List<Map<String, dynamic>> salesRows,
  required List<Map<String, dynamic>> inventoryAlerts,
}) {
  final byKey = <String, _MutableProduct>{};

  void ingest(Map<String, dynamic> row, {required bool fromSales}) {
    final id = _str(row['part_id'] ?? row['id']);
    final code = _str(row['part_code'] ?? row['code']);
    final name = _str(row['part_name'] ?? row['name']);
    final key = id.isNotEmpty ? id : (code.isNotEmpty ? code : name);
    if (key.isEmpty) return;

    final entry = byKey.putIfAbsent(
      key,
      () => _MutableProduct(partId: id, code: code, name: name),
    );
    if (code.isNotEmpty) entry.code = code;
    if (name.isNotEmpty) entry.name = name;
    if (id.isNotEmpty) entry.partId = id;

    if (fromSales) {
      entry.quantitySold += _int(row['quantity'] ?? row['qty'] ?? row['total_qty']);
      entry.revenue += _double(
        row['total'] ?? row['revenue'] ?? row['amount'] ?? row['sales'],
      );
    } else {
      final qty = _int(row['quantity'] ?? row['qty'] ?? row['stock']);
      entry.stockQty = qty;
      entry.lowStock = true;
    }
  }

  for (final row in salesRows) {
    ingest(row, fromSales: true);
  }
  for (final row in inventoryAlerts) {
    ingest(row, fromSales: false);
  }

  final items = byKey.values
      .map(
        (m) => ProductAnalysisItem(
          partId: m.partId,
          code: m.code,
          name: m.name,
          quantitySold: m.quantitySold,
          revenue: m.revenue,
          stockQty: m.stockQty,
          lowStock: m.lowStock,
        ),
      )
      .toList();

  items.sort((a, b) {
    final byRev = b.revenue.compareTo(a.revenue);
    if (byRev != 0) return byRev;
    return b.quantitySold.compareTo(a.quantitySold);
  });

  return items;
}

List<Map<String, dynamic>> extractSalesProductRows(Map<String, dynamic>? sales) {
  if (sales == null) return [];
  for (final key in [
    'products',
    'by_product',
    'by_part',
    'top_products',
    'top_parts',
    'items',
    'lines',
  ]) {
    final v = sales[key];
    if (v is List) {
      return v.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
  }
  if (sales['points'] is List) {
    return (sales['points'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return [];
}

class _MutableProduct {
  _MutableProduct({
    required this.partId,
    required this.code,
    required this.name,
  });

  String partId;
  String code;
  String name;
  int quantitySold = 0;
  double revenue = 0;
  int? stockQty;
  bool lowStock = false;
}

String _str(dynamic v) => v == null ? '' : '$v';

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

double _double(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}
