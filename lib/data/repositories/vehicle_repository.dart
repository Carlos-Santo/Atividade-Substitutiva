import 'package:sqflite/sqflite.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/models/catalog_item.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/models/vehicle_type.dart';
import '../services/database/app_database.dart';
import '../services/database/storage_guard.dart';

/// Acesso ao veículo cadastrado.
abstract interface class VehicleRepository {
  /// Veículo atual, ou nulo se ainda não houver cadastro.
  Future<Vehicle?> getCurrent();

  /// Cadastra o veículo. Lança [BusinessRuleException] se já existir um,
  /// pois o app trabalha com apenas um veículo por vez.
  Future<Vehicle> register(Vehicle vehicle);

  /// Exclui o veículo e todos os abastecimentos dele.
  Future<void> delete(int vehicleId);
}

class SqliteVehicleRepository implements VehicleRepository {
  SqliteVehicleRepository(this._database);

  final AppDatabase _database;
  Database get _db => _database.db;

  @override
  Future<Vehicle?> getCurrent() => guardStorage(() async {
    final rows = await _db.query(
      VehiclesTable.name,
      orderBy: '${VehiclesTable.id} DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  });

  @override
  Future<Vehicle> register(Vehicle vehicle) => guardStorage(
    () => _db.transaction((txn) async {
      final count = Sqflite.firstIntValue(
        await txn.rawQuery('SELECT COUNT(*) FROM ${VehiclesTable.name}'),
      );
      if ((count ?? 0) > 0) {
        throw const BusinessRuleException(
          'Já existe um veículo cadastrado. Exclua o atual para cadastrar outro.',
        );
      }
      final id = await txn.insert(VehiclesTable.name, _toRow(vehicle));
      return vehicle.copyWith(id: id);
    }),
  );

  @override
  Future<void> delete(int vehicleId) => guardStorage(
    () => _db.transaction((txn) async {
      // O ON DELETE CASCADE já cuidaria disso; a exclusão explícita deixa a
      // regra visível e não depende da configuração do SQLite.
      await txn.delete(
        RefuelingsTable.name,
        where: '${RefuelingsTable.vehicleId} = ?',
        whereArgs: [vehicleId],
      );
      await txn.delete(
        VehiclesTable.name,
        where: '${VehiclesTable.id} = ?',
        whereArgs: [vehicleId],
      );
    }),
  );

  static Map<String, Object?> _toRow(Vehicle v) => {
    VehiclesTable.type: v.type.name,
    VehiclesTable.brandCode: v.brand.code,
    VehiclesTable.brandName: v.brand.name,
    VehiclesTable.modelCode: v.model.code,
    VehiclesTable.modelName: v.model.name,
    VehiclesTable.year: v.year,
    VehiclesTable.engineCc: v.engineDisplacementCc,
    VehiclesTable.createdAt: DateTime.now().millisecondsSinceEpoch,
  };

  static Vehicle _fromRow(Map<String, Object?> row) => Vehicle(
    id: row[VehiclesTable.id]! as int,
    type: VehicleType.values.byName(row[VehiclesTable.type]! as String),
    brand: CatalogItem(
      code: row[VehiclesTable.brandCode]! as String,
      name: row[VehiclesTable.brandName]! as String,
    ),
    model: CatalogItem(
      code: row[VehiclesTable.modelCode]! as String,
      name: row[VehiclesTable.modelName]! as String,
    ),
    year: row[VehiclesTable.year]! as int,
    engineDisplacementCc: row[VehiclesTable.engineCc]! as int,
  );
}
