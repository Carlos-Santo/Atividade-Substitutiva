import 'dart:async';

import 'package:tanque_cheio/core/errors/app_exception.dart';
import 'package:tanque_cheio/data/repositories/refueling_repository.dart';
import 'package:tanque_cheio/data/repositories/vehicle_catalog_repository.dart';
import 'package:tanque_cheio/data/repositories/vehicle_repository.dart';
import 'package:tanque_cheio/domain/models/catalog_item.dart';
import 'package:tanque_cheio/domain/models/fuel_type.dart';
import 'package:tanque_cheio/domain/models/refueling.dart';
import 'package:tanque_cheio/domain/models/vehicle.dart';
import 'package:tanque_cheio/domain/models/vehicle_type.dart';

/// Repositórios em memória para testes: mesmo contrato das versões SQLite,
/// sem banco de dados.
class InMemoryVehicleRepository implements VehicleRepository {
  InMemoryVehicleRepository({Vehicle? initial}) : _vehicle = initial;

  Vehicle? _vehicle;
  int _nextId = 1;
  InMemoryRefuelingRepository? linkedRefuelings;

  @override
  Future<Vehicle?> getCurrent() async => _vehicle;

  @override
  Future<Vehicle> register(Vehicle vehicle) async {
    if (_vehicle != null) {
      throw const BusinessRuleException('Já existe um veículo cadastrado.');
    }
    return _vehicle = vehicle.copyWith(id: _nextId++);
  }

  @override
  Future<void> delete(int vehicleId) async {
    linkedRefuelings?.removeWhere((r) => r.vehicleId == vehicleId);
    if (_vehicle?.id == vehicleId) _vehicle = null;
  }
}

class InMemoryRefuelingRepository implements RefuelingRepository {
  InMemoryRefuelingRepository([Iterable<Refueling> initial = const []]) {
    for (final r in initial) {
      final id = r.id ?? _nextId;
      _items[id] = r.copyWith(id: id);
      if (id >= _nextId) _nextId = id + 1;
    }
  }

  final _items = <int, Refueling>{};
  int _nextId = 1;

  /// Quando definido, todas as operações falham com este erro.
  AppException? failWith;

  void removeWhere(bool Function(Refueling) test) =>
      _items.removeWhere((_, r) => test(r));

  @override
  Future<List<Refueling>> getByVehicle(int vehicleId) async {
    _maybeFail();
    return _items.values.where((r) => r.vehicleId == vehicleId).toList()
      ..sort(Refueling.chronological);
  }

  @override
  Future<Refueling> save(Refueling refueling) async {
    _maybeFail();
    final saved = refueling.copyWith(id: refueling.id ?? _nextId++);
    _items[saved.id!] = saved;
    return saved;
  }

  @override
  Future<void> delete(int refuelingId) async {
    _maybeFail();
    _items.remove(refuelingId);
  }

  void _maybeFail() {
    final error = failWith;
    if (error != null) throw error;
  }
}

/// Catálogo falso. Por padrão responde na hora; com [manual] = true, as
/// respostas ficam pendentes até o teste completá-las (útil para testar
/// carregamento e respostas fora de ordem).
class FakeCatalogRepository implements VehicleCatalogRepository {
  FakeCatalogRepository({this.manual = false});

  final bool manual;
  final brandRequests = <VehicleType>[];
  final modelRequests = <String>[];
  final pending = <String, Completer<List<CatalogItem>>>{};
  AppException? failBrandsWith;
  AppException? failModelsWith;

  static const fiat = CatalogItem(code: '21', name: 'Fiat');
  static const vw = CatalogItem(code: '59', name: 'VW - VolksWagen');
  static const honda = CatalogItem(code: '80', name: 'HONDA');
  static const argo = CatalogItem(code: '8051', name: 'ARGO DRIVE 1.3 8V Flex');
  static const mobi = CatalogItem(
    code: '7539',
    name: 'MOBI LIKE 1.0 Fire Flex 5p.',
  );
  static const gol = CatalogItem(code: '9001', name: 'Gol 1.6 Flex');
  static const cg = CatalogItem(code: '7777', name: 'CG 160 TITAN Flex');

  static const brands = {
    VehicleType.car: [fiat, vw],
    VehicleType.motorcycle: [honda],
    VehicleType.truck: <CatalogItem>[],
  };
  static const models = {
    '21': [argo, mobi],
    '59': [gol],
    '80': [cg],
  };

  @override
  Future<List<CatalogItem>> getBrands(VehicleType type) {
    brandRequests.add(type);
    final error = failBrandsWith;
    if (error != null) return Future.error(error);
    return _respond('brands/${type.name}', brands[type]!);
  }

  @override
  Future<List<CatalogItem>> getModels(VehicleType type, String brandCode) {
    modelRequests.add(brandCode);
    final error = failModelsWith;
    if (error != null) return Future.error(error);
    return _respond('models/$brandCode', models[brandCode] ?? const []);
  }

  Future<List<CatalogItem>> _respond(String key, List<CatalogItem> value) {
    if (!manual) return Future.value(value);
    return (pending[key] = Completer<List<CatalogItem>>()).future;
  }

  void complete(String key) {
    final value = key.startsWith('brands/')
        ? brands[VehicleType.values.byName(key.substring(7))]!
        : models[key.substring(7)] ?? const <CatalogItem>[];
    pending.remove(key)!.complete(value);
  }
}

/// Veículo ainda não salvo (sem id).
const unsavedVehicle = Vehicle(
  type: VehicleType.car,
  brand: FakeCatalogRepository.fiat,
  model: FakeCatalogRepository.argo,
  year: 2022,
  engineDisplacementCc: 1300,
);

/// Mesmo veículo, já salvo com id 1.
final testVehicle = unsavedVehicle.copyWith(id: 1);

/// Atalho para montar abastecimentos nos testes.
Refueling refuelingAt({
  int? id,
  int vehicleId = 1,
  required int km,
  required double liters,
  double price = 5.0,
  required DateTime date,
  FuelType fuel = FuelType.gasoline,
}) => Refueling(
  id: id,
  vehicleId: vehicleId,
  fuelType: fuel,
  pricePerLiter: price,
  liters: liters,
  odometerKm: km,
  date: date,
);
