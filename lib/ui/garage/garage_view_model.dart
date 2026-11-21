import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/repositories/refueling_repository.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../domain/models/consumption_report.dart';
import '../../domain/models/odometer_range.dart';
import '../../domain/models/refueling.dart';
import '../../domain/models/vehicle.dart';

enum GarageStatus { loading, ready, failure }

/// Estado compartilhado do app: o veículo, seus abastecimentos e os
/// indicadores calculados.
///
/// As telas leem daqui e pedem as alterações por aqui. Os métodos que
/// alteram dados lançam [AppException] em caso de falha, para que a tela
/// mostre a mensagem no lugar certo (por exemplo, num SnackBar).
class GarageViewModel extends ChangeNotifier {
  GarageViewModel({
    required VehicleRepository vehicleRepository,
    required RefuelingRepository refuelingRepository,
  }) : _vehicles = vehicleRepository,
       _refuelings = refuelingRepository;

  final VehicleRepository _vehicles;
  final RefuelingRepository _refuelings;

  GarageStatus _status = GarageStatus.loading;
  GarageStatus get status => _status;

  AppException? _loadError;
  AppException? get loadError => _loadError;

  Vehicle? _vehicle;
  Vehicle? get vehicle => _vehicle;
  bool get hasVehicle => _vehicle != null;

  List<Refueling> _history = const [];

  /// Abastecimentos em ordem cronológica.
  List<Refueling> get refuelings => _history;

  ConsumptionReport _report = ConsumptionReport.empty;
  ConsumptionReport get report => _report;

  /// Avisa só quando muda o que interessa à navegação: o status de
  /// carregamento e a existência de um veículo.
  ///
  /// O roteador escuta este valor em vez do ViewModel inteiro. Assim, salvar
  /// um abastecimento não reavalia as rotas (o que poderia desfazer o `pop`
  /// do formulário).
  late final ValueNotifier<({GarageStatus status, bool hasVehicle})>
  navigationState = ValueNotifier(_currentNavigationState);

  ({GarageStatus status, bool hasVehicle}) get _currentNavigationState =>
      (status: _status, hasVehicle: hasVehicle);

  @override
  void notifyListeners() {
    navigationState.value = _currentNavigationState;
    super.notifyListeners();
  }

  @override
  void dispose() {
    navigationState.dispose();
    super.dispose();
  }

  /// Carrega os dados salvos no aparelho. Chamado ao abrir o app.
  Future<void> load() async {
    _status = GarageStatus.loading;
    _loadError = null;
    notifyListeners();
    try {
      _vehicle = await _vehicles.getCurrent();
      await _reloadRefuelings(notify: false);
      _status = GarageStatus.ready;
    } on AppException catch (e) {
      _loadError = e;
      _status = GarageStatus.failure;
    }
    notifyListeners();
  }

  Future<void> registerVehicle(Vehicle vehicle) async {
    _vehicle = await _vehicles.register(vehicle);
    _setHistory(const []);
  }

  /// Exclui o veículo atual e todos os seus abastecimentos.
  Future<void> deleteVehicle() async {
    final id = _vehicle?.id;
    if (id == null) return;
    await _vehicles.delete(id);
    _vehicle = null;
    _setHistory(const []);
  }

  Refueling? findRefueling(int id) {
    for (final item in _history) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Faixa de quilometragem válida para um abastecimento em [date].
  OdometerRange odometerRangeFor(DateTime date, {int? editingId}) =>
      OdometerRange.forDate(_history, date, ignoreId: editingId);

  /// Salva um abastecimento novo ou editado, validando a quilometragem.
  Future<Refueling> saveRefueling(Refueling refueling) async {
    final vehicleId = _vehicle?.id;
    if (vehicleId == null) {
      throw const BusinessRuleException('Cadastre um veículo primeiro.');
    }
    final range = odometerRangeFor(refueling.date, editingId: refueling.id);
    if (!range.contains(refueling.odometerKm)) {
      throw const BusinessRuleException(
        'A quilometragem não combina com os abastecimentos vizinhos.',
      );
    }
    final saved = await _refuelings.save(
      refueling.copyWith(vehicleId: vehicleId),
    );
    await _reloadRefuelings();
    return saved;
  }

  Future<void> deleteRefueling(int refuelingId) async {
    await _refuelings.delete(refuelingId);
    await _reloadRefuelings();
  }

  Future<void> _reloadRefuelings({bool notify = true}) async {
    final id = _vehicle?.id;
    final history = id == null
        ? const <Refueling>[]
        : await _refuelings.getByVehicle(id);
    _setHistory(history, notify: notify);
  }

  void _setHistory(List<Refueling> history, {bool notify = true}) {
    final sorted = [...history]..sort(Refueling.chronological);
    _history = List.unmodifiable(sorted);
    _report = ConsumptionReport.from(_history);
    if (notify) notifyListeners();
  }
}
