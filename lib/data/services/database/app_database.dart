import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_factory.dart';

/// Banco SQLite local do app.
///
/// Guarda o veículo e os abastecimentos no próprio aparelho, então os dados
/// continuam lá depois que o app é fechado. A chave estrangeira com
/// `ON DELETE CASCADE` garante que excluir o veículo apaga também os seus
/// abastecimentos.
class AppDatabase {
  AppDatabase._(this.db);

  static const fileName = 'tanque_cheio.db';
  static const schemaVersion = 1;

  final Database db;

  /// Abre (ou cria) o banco. Em testes, passe [factory] e [path]
  /// (por exemplo [inMemoryDatabasePath]).
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final dbFactory = factory ?? createDatabaseFactory();
    final dbPath = path ?? p.join(await databaseDirectory(dbFactory), fileName);
    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _createSchema,
        onUpgrade: _migrate,
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _createSchema(Database db, int version) async {
    final batch = db.batch()
      ..execute('''
        CREATE TABLE ${VehiclesTable.name} (
          ${VehiclesTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${VehiclesTable.type} TEXT NOT NULL,
          ${VehiclesTable.brandCode} TEXT NOT NULL,
          ${VehiclesTable.brandName} TEXT NOT NULL,
          ${VehiclesTable.modelCode} TEXT NOT NULL,
          ${VehiclesTable.modelName} TEXT NOT NULL,
          ${VehiclesTable.year} INTEGER NOT NULL,
          ${VehiclesTable.engineCc} INTEGER NOT NULL,
          ${VehiclesTable.createdAt} INTEGER NOT NULL
        )
      ''')
      ..execute('''
        CREATE TABLE ${RefuelingsTable.name} (
          ${RefuelingsTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${RefuelingsTable.vehicleId} INTEGER NOT NULL
            REFERENCES ${VehiclesTable.name}(${VehiclesTable.id})
            ON DELETE CASCADE,
          ${RefuelingsTable.fuelType} TEXT NOT NULL,
          ${RefuelingsTable.pricePerLiter} REAL NOT NULL CHECK (${RefuelingsTable.pricePerLiter} > 0),
          ${RefuelingsTable.liters} REAL NOT NULL CHECK (${RefuelingsTable.liters} > 0),
          ${RefuelingsTable.odometerKm} INTEGER NOT NULL CHECK (${RefuelingsTable.odometerKm} >= 0),
          ${RefuelingsTable.refueledAt} INTEGER NOT NULL
        )
      ''')
      ..execute('''
        CREATE INDEX idx_refuelings_vehicle_date
        ON ${RefuelingsTable.name}(${RefuelingsTable.vehicleId}, ${RefuelingsTable.refueledAt})
      ''');
    await batch.commit(noResult: true);
  }

  /// Migrações futuras do esquema entram aqui, uma por versão:
  /// `if (oldVersion < 2) { ... }`.
  static Future<void> _migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {}

  Future<void> close() => db.close();
}

/// Nomes da tabela de veículos, para não repetir strings soltas.
abstract final class VehiclesTable {
  static const name = 'vehicles';
  static const id = 'id';
  static const type = 'type';
  static const brandCode = 'brand_code';
  static const brandName = 'brand_name';
  static const modelCode = 'model_code';
  static const modelName = 'model_name';
  static const year = 'year';
  static const engineCc = 'engine_cc';
  static const createdAt = 'created_at';
}

/// Nomes da tabela de abastecimentos.
abstract final class RefuelingsTable {
  static const name = 'refuelings';
  static const id = 'id';
  static const vehicleId = 'vehicle_id';
  static const fuelType = 'fuel_type';
  static const pricePerLiter = 'price_per_liter';
  static const liters = 'liters';
  static const odometerKm = 'odometer_km';
  static const refueledAt = 'refueled_at';
}
