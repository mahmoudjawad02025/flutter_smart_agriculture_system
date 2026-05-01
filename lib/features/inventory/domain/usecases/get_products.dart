import 'package:smart_cucumber_agriculture_system/features/inventory/domain/repositories/product_repo.dart';

class GetProducts {
  GetProducts(this._repo);
  final InventoryRepository _repo;

  Future<void> call() => _repo.syncProducts();
}

