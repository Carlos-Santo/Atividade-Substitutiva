import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanque_cheio/app.dart';

import 'fakes.dart';

/// Tamanho de um celular comum (392 × 872 pontos).
const phoneSize = Size(392, 872);

/// Tamanho de um tablet na horizontal.
const tabletSize = Size(1280, 800);

/// Sobe o app completo com repositórios falsos, num tamanho de tela fixo.
Future<void> pumpApp(
  WidgetTester tester, {
  InMemoryVehicleRepository? vehicles,
  InMemoryRefuelingRepository? refuelings,
  FakeCatalogRepository? catalog,
  Size size = phoneSize,
}) async {
  tester.view
    ..physicalSize = size * 2
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final refuelingRepository = refuelings ?? InMemoryRefuelingRepository();
  final vehicleRepository = (vehicles ?? InMemoryVehicleRepository())
    ..linkedRefuelings = refuelingRepository;

  await tester.pumpWidget(
    TanqueCheioApp(
      vehicleRepository: vehicleRepository,
      refuelingRepository: refuelingRepository,
      catalogRepository: catalog ?? FakeCatalogRepository(),
    ),
  );
  await tester.pumpAndSettle();
}
