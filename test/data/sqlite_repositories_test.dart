import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tanque_cheio/core/errors/app_exception.dart';
import 'package:tanque_cheio/data/repositories/refueling_repository.dart';
import 'package:tanque_cheio/data/repositories/vehicle_repository.dart';
import 'package:tanque_cheio/data/services/database/app_database.dart';
import 'package:tanque_cheio/domain/models/fuel_type.dart';

import '../helpers/fakes.dart';

/// Testes com SQLite real (via FFI) em um banco em memória.
void main() {
  late AppDatabase database;
  late SqliteVehicleRepository vehicles;
  late SqliteRefuelingRepository refuelings;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    vehicles = SqliteVehicleRepository(database);
    refuelings = SqliteRefuelingRepository(database);
  });

  tearDown(() => database.close());

  const unsaved = unsavedVehicle;

  group('SqliteVehicleRepository', () {
    test('começa sem veículo', () async {
      expect(await vehicles.getCurrent(), isNull);
    });

    test('cadastra e lê o veículo com todos os campos', () async {
      final saved = await vehicles.register(unsaved);

      expect(saved.id, isNotNull);
      final loaded = await vehicles.getCurrent();
      expect(loaded, saved);
      expect(loaded!.brand.name, 'Fiat');
      expect(loaded.model.code, '8051');
      expect(loaded.engineDisplacementCc, 1300);
    });

    test('permite apenas um veículo por vez', () async {
      await vehicles.register(unsaved);

      expect(vehicles.register(unsaved), throwsA(isA<BusinessRuleException>()));
    });

    test('excluir o veículo remove também os abastecimentos', () async {
      final vehicle = await vehicles.register(unsaved);
      await refuelings.save(
        refuelingAt(
          vehicleId: vehicle.id!,
          km: 100,
          liters: 10,
          date: DateTime(2026),
        ),
      );
      await refuelings.save(
        refuelingAt(
          vehicleId: vehicle.id!,
          km: 500,
          liters: 30,
          date: DateTime(2026, 2),
        ),
      );

      await vehicles.delete(vehicle.id!);

      expect(await vehicles.getCurrent(), isNull);
      expect(await refuelings.getByVehicle(vehicle.id!), isEmpty);
      final rows = await database.db.query(RefuelingsTable.name);
      expect(rows, isEmpty);

      // Depois de excluir, um novo cadastro é aceito.
      expect((await vehicles.register(unsaved)).id, isNotNull);
    });
  });

  group('SqliteRefuelingRepository', () {
    late int vehicleId;

    setUp(() async {
      vehicleId = (await vehicles.register(unsaved)).id!;
    });

    test('insere e devolve em ordem cronológica', () async {
      await refuelings.save(
        refuelingAt(
          vehicleId: vehicleId,
          km: 900,
          liters: 30,
          date: DateTime(2026, 3),
        ),
      );
      await refuelings.save(
        refuelingAt(
          vehicleId: vehicleId,
          km: 100,
          liters: 40,
          date: DateTime(2026),
        ),
      );

      final list = await refuelings.getByVehicle(vehicleId);
      expect(list.map((r) => r.odometerKm), [100, 900]);
      expect(list.every((r) => r.id != null), isTrue);
    });

    test('preserva valores decimais e data com horário', () async {
      final date = DateTime(2026, 11, 20, 14, 35);
      final saved = await refuelings.save(
        refuelingAt(
          vehicleId: vehicleId,
          km: 45200,
          liters: 40.512,
          price: 5.899,
          date: date,
          fuel: FuelType.ethanol,
        ),
      );

      final loaded = (await refuelings.getByVehicle(vehicleId)).single;
      expect(loaded, saved);
      expect(loaded.date, date);
      expect(loaded.fuelType, FuelType.ethanol);
      expect(loaded.pricePerLiter, 5.899);
    });

    test('atualiza um registro existente', () async {
      final saved = await refuelings.save(
        refuelingAt(
          vehicleId: vehicleId,
          km: 100,
          liters: 40,
          date: DateTime(2026),
        ),
      );

      await refuelings.save(
        saved.copyWith(liters: 42, fuelType: FuelType.diesel),
      );

      final loaded = (await refuelings.getByVehicle(vehicleId)).single;
      expect(loaded.liters, 42);
      expect(loaded.fuelType, FuelType.diesel);
    });

    test('atualizar registro inexistente lança erro de regra', () async {
      expect(
        refuelings.save(
          refuelingAt(
            id: 999,
            vehicleId: vehicleId,
            km: 1,
            liters: 1,
            date: DateTime(2026),
          ),
        ),
        throwsA(isA<BusinessRuleException>()),
      );
    });

    test('exclui um abastecimento', () async {
      final saved = await refuelings.save(
        refuelingAt(
          vehicleId: vehicleId,
          km: 100,
          liters: 40,
          date: DateTime(2026),
        ),
      );

      await refuelings.delete(saved.id!);

      expect(await refuelings.getByVehicle(vehicleId), isEmpty);
    });

    test('erro do SQLite vira StorageException', () async {
      // Veículo inexistente viola a chave estrangeira.
      expect(
        refuelings.save(
          refuelingAt(vehicleId: 12345, km: 1, liters: 1, date: DateTime(2026)),
        ),
        throwsA(isA<StorageException>()),
      );
    });
  });
}
