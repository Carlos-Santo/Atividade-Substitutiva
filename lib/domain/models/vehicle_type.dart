/// Categorias de veículo aceitas pela tabela FIPE da BrasilAPI.
///
/// O [apiPath] é o segmento usado nas rotas `/fipe/marcas/v1/{tipo}` e
/// `/fipe/veiculos/v1/{tipo}/{marca}`.
enum VehicleType {
  car(apiPath: 'carros', label: 'Carro'),
  motorcycle(apiPath: 'motos', label: 'Moto'),
  truck(apiPath: 'caminhoes', label: 'Caminhão');

  const VehicleType({required this.apiPath, required this.label});

  final String apiPath;
  final String label;
}
