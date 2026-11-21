import '../../domain/models/catalog_item.dart';
import '../../domain/models/vehicle_type.dart';
import '../services/brasil_api_client.dart';

/// Fonte das opções de marca e modelo do cadastro de veículo.
abstract interface class VehicleCatalogRepository {
  Future<List<CatalogItem>> getBrands(VehicleType type);
  Future<List<CatalogItem>> getModels(VehicleType type, String brandCode);
}

/// Implementação que consulta a BrasilAPI e guarda as respostas em memória
/// durante a sessão, evitando requisições repetidas ao trocar de marca.
class RemoteVehicleCatalogRepository implements VehicleCatalogRepository {
  RemoteVehicleCatalogRepository(this._api);

  final BrasilApiClient _api;
  final _brands = <VehicleType, Future<List<CatalogItem>>>{};
  final _models = <String, Future<List<CatalogItem>>>{};

  @override
  Future<List<CatalogItem>> getBrands(VehicleType type) =>
      _cached(_brands, type, () => _api.fetchBrands(type));

  @override
  Future<List<CatalogItem>> getModels(VehicleType type, String brandCode) =>
      _cached(
        _models,
        '${type.name}/$brandCode',
        () => _api.fetchModels(type, brandCode),
      );

  /// Reaproveita a mesma requisição para chamadas simultâneas e só guarda
  /// respostas bem-sucedidas, para que uma falha possa ser tentada de novo.
  Future<List<CatalogItem>> _cached<K>(
    Map<K, Future<List<CatalogItem>>> cache,
    K key,
    Future<List<CatalogItem>> Function() fetch,
  ) {
    return cache.putIfAbsent(key, () async {
      try {
        final items = await fetch();
        return List.unmodifiable(items..sort(_byName));
      } catch (_) {
        cache.remove(key)?.ignore();
        rethrow;
      }
    });
  }

  static int _byName(CatalogItem a, CatalogItem b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
