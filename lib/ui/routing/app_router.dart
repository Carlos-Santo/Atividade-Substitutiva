import 'package:go_router/go_router.dart';

import '../dashboard/dashboard_page.dart';
import '../garage/garage_view_model.dart';
import '../refueling/refueling_form_page.dart';
import '../refueling/refueling_list_page.dart';
import '../shell/home_shell.dart';
import '../splash/splash_page.dart';
import '../vehicle/vehicle_details_page.dart';
import '../vehicle/vehicle_setup_page.dart';
import 'routes.dart';

/// Cria o roteador do app.
///
/// O roteador escuta o estado de navegação do [GarageViewModel] e
/// redireciona sozinho:
/// * enquanto os dados carregam (ou se falharem), mostra a splash;
/// * sem veículo, só a tela de cadastro fica acessível;
/// * com veículo, a tela de cadastro leva ao dashboard.
///
/// Assim as telas não precisam decidir para onde ir depois de cadastrar ou
/// excluir o veículo.
GoRouter createAppRouter(GarageViewModel garage) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: garage.navigationState,
    redirect: (context, state) => _redirect(garage, state.matchedLocation),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routes.vehicleSetup,
        builder: (context, state) => const VehicleSetupPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.dashboard,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.refuelings,
                builder: (context, state) => const RefuelingListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.vehicle,
                builder: (context, state) => const VehicleDetailsPage(),
              ),
            ],
          ),
        ],
      ),
      // Formulários abrem por cima da navegação principal, em tela cheia.
      GoRoute(
        path: Routes.newRefueling,
        builder: (context, state) => const RefuelingFormPage(),
      ),
      GoRoute(
        path: '${Routes.refuelings}/:id',
        builder: (context, state) => RefuelingFormPage(
          refuelingId: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
    ],
  );
}

String? _redirect(GarageViewModel garage, String location) {
  if (garage.status != GarageStatus.ready) {
    return location == Routes.splash ? null : Routes.splash;
  }
  if (!garage.hasVehicle) {
    return location == Routes.vehicleSetup ? null : Routes.vehicleSetup;
  }
  if (location == Routes.splash || location == Routes.vehicleSetup) {
    return Routes.dashboard;
  }
  return null;
}
