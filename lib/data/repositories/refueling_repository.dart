import 'package:sqflite/sqflite.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/models/fuel_type.dart';
import '../../domain/models/refueling.dart';
import '../services/database/app_database.dart';
import '../services/database/storage_guard.dart';

/// Acesso aos abastecimentos do veículo.
abstract interface class RefuelingRepository {
  /// Abastecimentos do veículo, em ordem cronológica.
  Future<List<Refueling>> getByVehicle(int vehicleId);

  /// Insere (quando [Refueling.id] é nulo) ou atualiza um abastecimento.
  Future<Refueling> save(Refueling refueling);

  Future<void> delete(int refuelingId);
}

class SqliteRefuelingRepository implements RefuelingRepository {
  SqliteRefuelingRepository(this._database);

  final AppDatabase _database;
  Database get _db => _database.db;

  @override
  Future<List<Refueling>> getByVehicle(int vehicleId) => guardStorage(() async {
    final rows = await _db.query(
      RefuelingsTable.name,
      where: '${RefuelingsTable.vehicleId} = ?',
      whereArgs: [vehicleId],
      orderBy:
          '${RefuelingsTable.refueledAt} ASC, '
          '${RefuelingsTable.odometerKm} ASC, '
          '${RefuelingsTable.id} ASC',
    );
    return rows.map(_fromRow).toList();
  });

  @override
  Future<Refueling> save(Refueling refueling) => guardStorage(() async {
    final id = refueling.id;
    if (id == null) {
      final newId = await _db.insert(RefuelingsTable.name, _toRow(refueling));
      return refueling.copyWith(id: newId);
    }
    final updated = await _db.update(
      RefuelingsTable.name,
      _toRow(refueling),
      where: '${RefuelingsTable.id} = ?',
      whereArgs: [id],
    );
    if (updated == 0) {
      throw const BusinessRuleException('Este abastecimento não existe mais.');
    }
    return refueling;
  });

  @override
  Future<void> delete(int refuelingId) => guardStorage(() async {
    await _db.delete(
      RefuelingsTable.name,
      where: '${RefuelingsTable.id} = ?',
      whereArgs: [refuelingId],
    );
  });

  static Map<String, Object?> _toRow(Refueling r) => {
    RefuelingsTable.vehicleId: r.vehicleId,
    RefuelingsTable.fuelType: r.fuelType.name,
    RefuelingsTable.pricePerLiter: r.pricePerLiter,
    RefuelingsTable.liters: r.liters,
    RefuelingsTable.odometerKm: r.odometerKm,
    RefuelingsTable.refueledAt: r.date.millisecondsSinceEpoch,
  };

  static Refueling _fromRow(Map<String, Object?> row) => Refueling(
    id: row[RefuelingsTable.id]! as int,
    vehicleId: row[RefuelingsTable.vehicleId]! as int,
    fuelType: FuelType.values.byName(row[RefuelingsTable.fuelType]! as String),
    pricePerLiter: (row[RefuelingsTable.pricePerLiter]! as num).toDouble(),
    liters: (row[RefuelingsTable.liters]! as num).toDouble(),
    odometerKm: row[RefuelingsTable.odometerKm]! as int,
    date: DateTime.fromMillisecondsSinceEpoch(
      row[RefuelingsTable.refueledAt]! as int,
    ),
  );
}
