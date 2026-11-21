/// Caminhos das telas do app, centralizados para evitar strings soltas.
abstract final class Routes {
  static const splash = '/';
  static const vehicleSetup = '/cadastro-veiculo';

  // Abas da navegação principal.
  static const dashboard = '/dashboard';
  static const refuelings = '/abastecimentos';
  static const vehicle = '/veiculo';

  static const newRefueling = '/abastecimentos/novo';
  static String editRefueling(int id) => '/abastecimentos/$id';
}
