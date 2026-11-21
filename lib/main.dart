import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'data/repositories/refueling_repository.dart';
import 'data/repositories/vehicle_catalog_repository.dart';
import 'data/repositories/vehicle_repository.dart';
import 'data/services/brasil_api_client.dart';
import 'data/services/database/app_database.dart';

/// Ponto de entrada: prepara as dependências e inicia o app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');

  final database = await AppDatabase.open();

  runApp(
    TanqueCheioApp(
      vehicleRepository: SqliteVehicleRepository(database),
      refuelingRepository: SqliteRefuelingRepository(database),
      catalogRepository: RemoteVehicleCatalogRepository(BrasilApiClient()),
    ),
  );
}
