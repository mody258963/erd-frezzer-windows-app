import '../../core/events/app_refresh_bus.dart';
import '../../core/images/part_image_cache.dart';
import '../local/app_database.dart';
import 'customer_repository.dart';
import 'inventory_repository.dart';
import 'part_repository.dart';

class CatalogSyncRepository {
  CatalogSyncRepository(
    this._inventoryRepository,
    this._customerRepository,
    this._partRepository,
    this._db,
    this._refreshBus,
  );

  final InventoryRepository _inventoryRepository;
  final CustomerRepository _customerRepository;
  final PartRepository _partRepository;
  final AppDatabase _db;
  final AppRefreshBus _refreshBus;

  /// Pulls customers, parts, and branch stock from API and removes stale local rows.
  Future<DateTime> refresh(String branchId) async {
    final stock = await _inventoryRepository.byBranch(branchId);
    final imageUrls = <String>[];
    final stockQty = <String, double>{};

    for (final row in stock) {
      stockQty[row.partId] = row.quantity;
      final part = row.part;
      if (part != null) {
        await _db.upsertPart(
          id: part.id,
          code: part.code,
          name: part.name,
          unit: part.unit,
          sellPrice: part.sellPrice,
          imageUrl: part.imageUrl,
          isActive: part.isActive,
        );
        final url = part.imageUrl;
        if (url != null && url.isNotEmpty) {
          imageUrls.add(url);
        }
      }
    }

    final syncedPartIds = <String>{...stockQty.keys};

    try {
      final allParts = await _partRepository.list(perPage: 500);
      for (final part in allParts) {
        syncedPartIds.add(part.id);
        await _db.upsertPart(
          id: part.id,
          code: part.code,
          name: part.name,
          unit: part.unit,
          sellPrice: part.sellPrice,
          imageUrl: part.imageUrl,
          isActive: part.isActive,
        );
        final url = part.imageUrl;
        if (url != null && url.isNotEmpty) {
          imageUrls.add(url);
        }
      }
    } catch (_) {
      // Inventory sync above is enough when parts API is unavailable.
    }

    await _db.deactivatePartsExcept(syncedPartIds);
    await _db.replaceBranchStock(branchId, stockQty);

    final customers = await _customerRepository.list(perPage: 500);
    final activeCustomerIds = <String>{};
    for (final c in customers) {
      if (!c.isActive) continue;
      activeCustomerIds.add(c.id);
      await _db.upsertCustomer(
        id: c.id,
        name: c.name,
        type: c.type,
        creditLimit: c.creditLimit,
        outstandingBalance: c.outstandingBalance,
        settlementCycle: c.settlementCycle,
        lastSettledAt: c.lastSettledAt,
        isActive: true,
      );
    }

    await _db.deactivateCustomersExcept(activeCustomerIds);

    PartImageCache.prefetchAll(imageUrls);

    final now = DateTime.now();
    await _db.setMeta('last_catalog_sync', now.toIso8601String());
    await _db.setMeta('branch_id', branchId);
    _refreshBus.notify(AppRefreshKind.catalog);
    return now;
  }

  /// Updates branch stock quantities only (faster than full catalog refresh).
  Future<void> refreshStockOnly(String branchId) async {
    final stock = await _inventoryRepository.byBranch(branchId);
    final stockQty = <String, double>{};
    for (final row in stock) {
      stockQty[row.partId] = row.quantity;
    }
    await _db.replaceBranchStock(branchId, stockQty);
    _refreshBus.notify(AppRefreshKind.catalog);
  }
}
