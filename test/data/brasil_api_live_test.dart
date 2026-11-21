// Teste de integração com a BrasilAPI real (precisa de internet).
// Fica desligado por padrão; para rodar:
//   flutter test --run-skipped --tags live
@Tags(['live'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tanque_cheio/data/services/brasil_api_client.dart';
import 'package:tanque_cheio/domain/models/vehicle_type.dart';

void main() {
  final client = BrasilApiClient();
  tearDownAll(client.close);

  test('lista marcas de carros e modelos da Fiat', () async {
    final brands = await client.fetchBrands(VehicleType.car);
    final fiat = brands.firstWhere((b) => b.name.toLowerCase() == 'fiat');

    final models = await client.fetchModels(VehicleType.car, fiat.code);

    expect(brands.length, greaterThan(50));
    expect(models, isNotEmpty);
    expect(models.every((m) => m.name.isNotEmpty && m.code.isNotEmpty), isTrue);
  });

  test('marcas de motos e caminhões também respondem', () async {
    expect(await client.fetchBrands(VehicleType.motorcycle), isNotEmpty);
    expect(await client.fetchBrands(VehicleType.truck), isNotEmpty);
  });
}
