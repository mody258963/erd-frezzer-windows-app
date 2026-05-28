import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Parts,
    StockRows,
    Customers,
    PendingInvoices,
    PendingInvoiceItems,
    AppMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(parts, parts.imageUrl);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'frostparts');
  }

  Future<void> upsertPart({
    required String id,
    required String code,
    required String name,
    required double sellPrice,
    String? imageUrl,
    bool isActive = true,
  }) async {
    await into(parts).insertOnConflictUpdate(
      PartsCompanion.insert(
        id: id,
        code: code,
        name: name,
        sellPrice: sellPrice,
        imageUrl: Value(imageUrl),
        isActive: Value(isActive),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> upsertStock({
    required String partId,
    required String branchId,
    required int quantity,
  }) async {
    await into(stockRows).insertOnConflictUpdate(
      StockRowsCompanion.insert(
        partId: partId,
        branchId: branchId,
        quantity: quantity,
      ),
    );
  }

  Future<void> upsertCustomer({
    required String id,
    required String name,
    required String type,
    double creditLimit = 0,
    double outstandingBalance = 0,
    bool isActive = true,
  }) async {
    await into(customers).insertOnConflictUpdate(
      CustomersCompanion.insert(
        id: id,
        name: name,
        type: type,
        creditLimit: Value(creditLimit),
        outstandingBalance: Value(outstandingBalance),
        isActive: Value(isActive),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<Part>> searchParts(String query, {int limit = 50}) {
    final q = query.trim().toLowerCase();
    final sel = select(parts)..where((p) => p.isActive.equals(true));
    if (q.isNotEmpty) {
      sel.where(
        (p) =>
            p.code.lower().like('%$q%') | p.name.lower().like('%$q%'),
      );
    }
    return (sel..limit(limit)).get();
  }

  Future<int> getStockQty(String partId, String branchId) async {
    final row = await (select(stockRows)
          ..where(
            (s) => s.partId.equals(partId) & s.branchId.equals(branchId),
          ))
        .getSingleOrNull();
    return row?.quantity ?? 0;
  }

  Future<void> decrementStock(
    String partId,
    String branchId,
    int qty,
  ) async {
    final current = await getStockQty(partId, branchId);
    await upsertStock(
      partId: partId,
      branchId: branchId,
      quantity: current - qty,
    );
  }

  Future<List<Customer>> getActiveCustomers() {
    return (select(customers)..where((c) => c.isActive.equals(true))).get();
  }

  Future<String?> getCustomerName(String id) async {
    final row = await (select(customers)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    return row?.name;
  }

  Future<String?> getMeta(String key) async {
    final row = await (select(appMeta)..where((m) => m.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String value) async {
    await into(appMeta).insertOnConflictUpdate(
      AppMetaCompanion.insert(key: key, value: value),
    );
  }

  Future<List<PendingInvoice>> pendingFifo() {
    return (select(pendingInvoices)
          ..where((p) => p.status.isNotIn(['synced']))
          ..orderBy([(p) => OrderingTerm.asc(p.createdAt)]))
        .get();
  }

  Future<List<PendingInvoiceItem>> itemsForInvoice(String localId) {
    return (select(pendingInvoiceItems)
          ..where((i) => i.localInvoiceId.equals(localId)))
        .get();
  }

  Future<void> updatePendingStatus(
    String localId, {
    required String status,
    String? serverInvoiceId,
    String? errorMessage,
    DateTime? syncedAt,
  }) async {
    await (update(pendingInvoices)..where((p) => p.localId.equals(localId)))
        .write(
      PendingInvoicesCompanion(
        status: Value(status),
        serverInvoiceId: Value(serverInvoiceId),
        errorMessage: Value(errorMessage),
        syncedAt: Value(syncedAt),
      ),
    );
  }
}
