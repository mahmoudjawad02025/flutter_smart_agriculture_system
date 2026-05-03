import 'package:flutter_smart_agriculture_system/features/inventory/domain/repositories/inventory_repo.dart';

class GetProducts {
  GetProducts(this._repo);
  final InventoryRepository _repo;

  Future<void> call() => _repo.syncProducts();
}
