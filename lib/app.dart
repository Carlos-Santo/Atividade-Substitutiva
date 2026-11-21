import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/repositories/refueling_repository.dart';
import 'data/repositories/vehicle_catalog_repository.dart';
import 'data/repositories/vehicle_repository.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/garage/garage_view_model.dart';
import 'ui/routing/app_router.dart';

/// Widget raiz do app.
///
/// Recebe os repositórios prontos (injeção de dependência pelo construtor).
/// Assim os testes podem trocar o banco e a API por versões falsas sem mudar
/// nenhuma tela.
class TanqueCheioApp extends StatefulWidget {
  const TanqueCheioApp({
    super.key,
    required this.vehicleRepository,
    required this.refuelingRepository,
    required this.catalogRepository,
  });

  final VehicleRepository vehicleRepository;
  final RefuelingRepository refuelingRepository;
  final VehicleCatalogRepository catalogRepository;

  @override
  State<TanqueCheioApp> createState() => _TanqueCheioAppState();
}

class _TanqueCheioAppState extends State<TanqueCheioApp> {
  late final GarageViewModel _garage;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _garage = GarageViewModel(
      vehicleRepository: widget.vehicleRepository,
      refuelingRepository: widget.refuelingRepository,
    )..load();
    _router = createAppRouter(_garage);
  }

  @override
  void dispose() {
    _router.dispose();
    _garage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<VehicleCatalogRepository>.value(
          value: widget.catalogRepository,
        ),
        ChangeNotifierProvider<GarageViewModel>.value(value: _garage),
      ],
      child: MaterialApp.router(
        title: 'Tanque Cheio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: _router,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
