import 'package:flutter_test/flutter_test.dart';
import 'package:tanque_cheio/core/errors/app_exception.dart';
import 'package:tanque_cheio/ui/garage/garage_view_model.dart';

import '../helpers/fakes.dart';

void main() {
  late InMemoryVehicleRepository vehicles;
  late InMemoryRefuelingRepository refuelings;
  late GarageViewModel garage;

  GarageViewModel build() => GarageViewModel(
    vehicleRepository: vehicles,
    refuelingRepository: refuelings,
  );

  setUp(() {
    refuelings = InMemoryRefuelingRepository([
      refuelingAt(id: 1, km: 1000, liters: 40, date: DateTime(2026)),
      refuelingAt(id: 2, km: 1500, liters: 40, date: DateTime(2026, 2)),
    ]);
    vehicles = InMemoryVehicleRepository(initial: testVehicle)
      ..linkedRefuelings = refuelings;
    garage = build();
  });

  test('carrega veículo, histórico e relatório', () async {
    expect(garage.status, GarageStatus.loading);

    await garage.load();

    expect(garage.status, GarageStatus.ready);
    expect(garage.vehicle, testVehicle);
    expect(garage.refuelings, hasLength(2));
    expect(garage.report.averageKmPerLiter, closeTo(12.5, 1e-9));
  });

  test('falha na leitura deixa o estado de erro', () async {
    refuelings.failWith = const StorageException();

    await garage.load();

    expect(garage.status, GarageStatus.failure);
    expect(garage.loadError, isA<StorageException>());
  });

  test('salvar abastecimento recalcula indicadores e avisa as telas', () async {
    await garage.load();
    var notifications = 0;
    garage.addListener(() => notifications++);

    await garage.saveRefueling(
      refuelingAt(km: 2000, liters: 50, date: DateTime(2026, 3)),
    );

    expect(garage.refuelings, hasLength(3));
    expect(garage.report.entries.last.kmPerLiter, closeTo(10, 1e-9));
    expect(notifications, greaterThan(0));
  });

  test('rejeita quilometragem incoerente com o histórico', () async {
    await garage.load();

    expect(
      () => garage.saveRefueling(
        refuelingAt(km: 1200, liters: 30, date: DateTime(2026, 3)),
      ),
      throwsA(isA<BusinessRuleException>()),
    );
  });

  test('excluir abastecimento atualiza o relatório', () async {
    await garage.load();

    await garage.deleteRefueling(2);

    expect(garage.refuelings.map((r) => r.id), [1]);
    expect(garage.report.averageKmPerLiter, isNull);
  });

  test('excluir veículo limpa tudo e permite novo cadastro', () async {
    await garage.load();

    await garage.deleteVehicle();

    expect(garage.hasVehicle, isFalse);
    expect(garage.refuelings, isEmpty);
    expect(await refuelings.getByVehicle(1), isEmpty);

    await garage.registerVehicle(unsavedVehicle);
    expect(garage.hasVehicle, isTrue);
    expect(garage.refuelings, isEmpty);
  });

  test('sem veículo não é possível registrar abastecimento', () async {
    vehicles = InMemoryVehicleRepository();
    garage = build();
    await garage.load();

    expect(
      () => garage.saveRefueling(
        refuelingAt(km: 1, liters: 1, date: DateTime(2026)),
      ),
      throwsA(isA<BusinessRuleException>()),
    );
  });

  test('estado de navegação só muda com veículo ou carregamento', () async {
    await garage.load();
    var routeChanges = 0;
    garage.navigationState.addListener(() => routeChanges++);

    await garage.saveRefueling(
      refuelingAt(km: 2000, liters: 50, date: DateTime(2026, 3)),
    );
    await garage.deleteRefueling(1);
    expect(routeChanges, 0);

    await garage.deleteVehicle();
    expect(routeChanges, 1);
    expect(garage.navigationState.value.hasVehicle, isFalse);
  });
}
