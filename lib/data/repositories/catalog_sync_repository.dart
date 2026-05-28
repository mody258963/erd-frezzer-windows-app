import '../../core/images/part_image_cache.dart';
import '../local/app_database.dart';
import 'customer_repository.dart';
import 'inventory_repository.dart';

class CatalogSyncRepository {
  CatalogSyncRepository(
    this._inventoryRepository,
    this._customerRepository,
    this._db,
  );

  final InventoryRepository _inventoryRepository;
  final CustomerRepository _customerRepository;
  final AppDatabase _db;

  Future<DateTime> refresh(String branchId) async {
    final stock = await _inventoryRepository.byBranch(branchId);
    final imageUrls = <String>[];
    for (final row in stock) {
      final part = row.part;
      if (part != null) {
        await _db.upsertPart(
          id: part.id,
          code: part.code,
          name: part.name,
          sellPrice: part.sellPrice,
          imageUrl: part.imageUrl,
          isActive: part.isActive,
        );
        final url = part.imageUrl;
        if (url != null && url.isNotEmpty) {
          imageUrls.add(url);
        }
      }
      await _db.upsertStock(
        partId: row.partId,
        branchId: row.branchId,
        quantity: row.quantity,
      );
    }

    final customers = await _customerRepository.list(perPage: 500);
    for (final c in customers) {
      await _db.upsertCustomer(
        id: c.id,
        name: c.name,
        type: c.type,
        creditLimit: c.creditLimit,
        outstandingBalance: c.outstandingBalance,
        isActive: c.isActive,
      );
    }

    // Warm disk cache for offline thumbnails (non-blocking for caller).
    PartImageCache.prefetchAll(imageUrls);

    final now = DateTime.now();
    await _db.setMeta('last_catalog_sync', now.toIso8601String());
    await _db.setMeta('branch_id', branchId);
    return now;
  }
}
