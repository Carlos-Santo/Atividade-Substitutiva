/// Tipos de combustível aceitos em um abastecimento.
enum FuelType {
  ethanol('Etanol'),
  gasoline('Gasolina'),
  diesel('Diesel');

  const FuelType(this.label);

  final String label;
}
