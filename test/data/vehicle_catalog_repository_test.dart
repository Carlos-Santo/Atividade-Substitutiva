import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tanque_cheio/core/errors/app_exception.dart';
import 'package:tanque_cheio/data/repositories/vehicle_catalog_repository.dart';
import 'package:tanque_cheio/data/services/brasil_api_client.dart';
import 'package:tanque_cheio/domain/models/vehicle_type.dart';

void main() {
  late int calls;
  late bool fail;
  late RemoteVehicleCatalogRepository repository;

  setUp(() {
    calls = 0;
    fail = false;
    repository = RemoteVehicleCatalogRepository(
      BrasilApiClient(
        httpClient: MockClient((request) async {
          calls++;
          if (fail) return http.Response('erro', 503);
          return http.Response.bytes(
            utf8.encode(
              jsonEncode([
                {'nome': 'volvo', 'valor': '2'},
                {'nome': 'Audi', 'valor': '1'},
              ]),
            ),
            200,
          );
        }),
      ),
    );
  });

  test('ordena por nome sem diferenciar maiúsculas', () async {
    final brands = await repository.getBrands(VehicleType.car);
    expect(brands.map((b) => b.name), ['Audi', 'volvo']);
  });

  test('guarda a resposta e não repete a requisição', () async {
    await repository.getBrands(VehicleType.car);
    await repository.getBrands(VehicleType.car);
    expect(calls, 1);

    await repository.getBrands(VehicleType.truck);
    expect(calls, 2);
  });

  test('não guarda falhas, permitindo tentar de novo', () async {
    fail = true;
    await expectLater(
      repository.getBrands(VehicleType.car),
      throwsA(isA<ApiException>()),
    );

    fail = false;
    final brands = await repository.getBrands(VehicleType.car);
    expect(brands, hasLength(2));
    expect(calls, 2);
  });
}
