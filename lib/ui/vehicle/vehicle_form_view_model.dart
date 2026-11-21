import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/repositories/vehicle_catalog_repository.dart';
import '../../domain/models/catalog_item.dart';
import '../../domain/models/displacement_hint.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/models/vehicle_type.dart';
import '../core/load_state.dart';

/// Estado do formulário de cadastro de veículo.
///
/// Cuida da consulta de marcas e modelos na API: os modelos dependem da
/// marca escolhida, e trocar o tipo ou a marca limpa as escolhas seguintes.
class VehicleFormViewModel extends ChangeNotifier {
  VehicleFormViewModel(this._catalog);

  final VehicleCatalogRepository _catalog;

  VehicleType _type = VehicleType.car;
  VehicleType get type => _type;

  LoadState<List<CatalogItem>> _brands = const Idle();
  LoadState<List<CatalogItem>> get brands => _brands;

  LoadState<List<CatalogItem>> _models = const Idle();
  LoadState<List<CatalogItem>> get models => _models;

  CatalogItem? _brand;
  CatalogItem? get brand => _brand;

  CatalogItem? _model;
  CatalogItem? get model => _model;

  /// Cilindrada sugerida pelo nome do modelo (por exemplo "1.6" → 1600).
  int? get suggestedDisplacementCc {
    final model = _model;
    return model == null ? null : DisplacementHint.fromModelName(model.name);
  }

  // Contadores de requisição: se o usuário trocar de marca antes da resposta
  // chegar, a resposta antiga é descartada em vez de sobrescrever a nova.
  int _brandsRequest = 0;
  int _modelsRequest = 0;
  bool _disposed = false;

  Future<void> loadBrands() async {
    final request = ++_brandsRequest;
    final type = _type;
    _brands = const Loading();
    _notify();
    final result = await _fetch(() => _catalog.getBrands(type));
    if (request != _brandsRequest) return;
    _brands = result;
    _notify();
  }

  Future<void> loadModels() async {
    final brand = _brand;
    if (brand == null) return;
    final request = ++_modelsRequest;
    final type = _type;
    _models = const Loading();
    _notify();
    final result = await _fetch(() => _catalog.getModels(type, brand.code));
    if (request != _modelsRequest) return;
    _models = result;
    _notify();
  }

  void selectType(VehicleType type) {
    if (type == _type) return;
    _type = type;
    _brand = null;
    _model = null;
    _models = const Idle();
    _modelsRequest++;
    loadBrands();
  }

  void selectBrand(CatalogItem brand) {
    if (brand == _brand) return;
    _brand = brand;
    _model = null;
    loadModels();
  }

  void selectModel(CatalogItem model) {
    _model = model;
    _notify();
  }

  /// Monta o veículo com as escolhas do formulário. Retorna nulo se marca ou
  /// modelo ainda não foram escolhidos.
  Vehicle? buildVehicle({required int year, required int displacementCc}) {
    final brand = _brand;
    final model = _model;
    if (brand == null || model == null) return null;
    return Vehicle(
      type: _type,
      brand: brand,
      model: model,
      year: year,
      engineDisplacementCc: displacementCc,
    );
  }

  Future<LoadState<List<CatalogItem>>> _fetch(
    Future<List<CatalogItem>> Function() fetch,
  ) async {
    try {
      return Loaded(await fetch());
    } on AppException catch (e) {
      return LoadFailed(e);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
