import 'package:smart_cucumber_agriculture_system/logic/repositories/product_repo.dart';

class GetProducts {
  GetProducts(this._repo);
  final ProductRepository _repo;

  Future<void> call() => _repo.syncProducts();
}
