import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/errors/app_exception.dart';
import '../../domain/models/catalog_item.dart';
import '../../domain/models/vehicle_type.dart';

/// Cliente HTTP da BrasilAPI (https://brasilapi.com.br), módulo FIPE.
///
/// Endpoints usados:
/// * `GET /api/fipe/marcas/v1/{tipo}`: marcas do tipo de veículo;
/// * `GET /api/fipe/veiculos/v1/{tipo}/{codigoMarca}`: modelos da marca.
///
/// Converte falhas de rede e respostas inválidas em [AppException].
class BrasilApiClient {
  BrasilApiClient({
    http.Client? httpClient,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client(),
       _baseUri = baseUri ?? defaultBaseUri;

  static final defaultBaseUri = Uri.parse('https://brasilapi.com.br/api/');

  final http.Client _http;
  final Uri _baseUri;
  final Duration timeout;

  Future<List<CatalogItem>> fetchBrands(VehicleType type) => _getList(
    'fipe/marcas/v1/${type.apiPath}',
    (json) => CatalogItem(
      code: _readString(json, 'valor'),
      name: _readString(json, 'nome'),
    ),
  );

  Future<List<CatalogItem>> fetchModels(VehicleType type, String brandCode) =>
      _getList(
        'fipe/veiculos/v1/${type.apiPath}/${Uri.encodeComponent(brandCode)}',
        (json) => CatalogItem(
          code: _readString(json, 'valor'),
          name: _readString(json, 'modelo'),
        ),
      );

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, Object?> json) parse,
  ) async {
    final http.Response response;
    try {
      response = await _http.get(_baseUri.resolve(path)).timeout(timeout);
    } on TimeoutException catch (e) {
      throw NetworkException(cause: e);
    } on http.ClientException catch (e) {
      throw NetworkException(cause: e);
    }

    if (response.statusCode != 200) {
      throw ApiException(statusCode: response.statusCode);
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) throw const FormatException('Esperava uma lista');
      return [
        for (final item in decoded)
          if (item is Map<String, Object?>) parse(item),
      ];
    } on FormatException catch (e) {
      throw ApiException(statusCode: response.statusCode, cause: e);
    }
  }

  static String _readString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) throw FormatException('Campo "$key" ausente');
    return value.toString().trim();
  }

  void close() => _http.close();
}
