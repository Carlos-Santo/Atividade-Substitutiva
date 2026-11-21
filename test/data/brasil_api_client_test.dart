import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tanque_cheio/core/errors/app_exception.dart';
import 'package:tanque_cheio/data/services/brasil_api_client.dart';
import 'package:tanque_cheio/domain/models/catalog_item.dart';
import 'package:tanque_cheio/domain/models/vehicle_type.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('busca marcas pelo tipo de veículo', () async {
    late Uri requested;
    final client = BrasilApiClient(
      httpClient: MockClient((request) async {
        requested = request.url;
        return _json([
          {'nome': 'Citroën', 'valor': '13'},
          {'nome': 'Fiat', 'valor': '21'},
        ]);
      }),
    );

    final brands = await client.fetchBrands(VehicleType.car);

    expect(
      requested.toString(),
      'https://brasilapi.com.br/api/fipe/marcas/v1/carros',
    );
    expect(brands, const [
      CatalogItem(code: '13', name: 'Citroën'),
      CatalogItem(code: '21', name: 'Fiat'),
    ]);
  });

  test('busca modelos da marca escolhida', () async {
    late Uri requested;
    final client = BrasilApiClient(
      httpClient: MockClient((request) async {
        requested = request.url;
        return _json([
          {'modelo': 'ARGO DRIVE 1.3 8V Flex', 'valor': '8051'},
        ]);
      }),
    );

    final models = await client.fetchModels(VehicleType.motorcycle, '80');

    expect(requested.path, '/api/fipe/veiculos/v1/motos/80');
    expect(models.single.name, 'ARGO DRIVE 1.3 8V Flex');
    expect(models.single.code, '8051');
  });

  test('status diferente de 200 vira ApiException', () async {
    final client = BrasilApiClient(
      httpClient: MockClient((_) async => _json({'message': 'erro'}, 500)),
    );

    expect(
      client.fetchBrands(VehicleType.truck),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 500)),
    );
  });

  test('JSON em formato inesperado vira ApiException', () async {
    final client = BrasilApiClient(
      httpClient: MockClient((_) async => _json({'nao': 'é lista'})),
    );

    expect(client.fetchBrands(VehicleType.car), throwsA(isA<ApiException>()));
  });

  test('falha de conexão vira NetworkException', () async {
    final client = BrasilApiClient(
      httpClient: MockClient((_) => throw http.ClientException('offline')),
    );

    expect(
      client.fetchBrands(VehicleType.car),
      throwsA(isA<NetworkException>()),
    );
  });

  test('tempo esgotado vira NetworkException', () async {
    final client = BrasilApiClient(
      timeout: const Duration(milliseconds: 10),
      httpClient: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return _json(const []);
      }),
    );

    expect(
      client.fetchBrands(VehicleType.car),
      throwsA(isA<NetworkException>()),
    );
  });
}
