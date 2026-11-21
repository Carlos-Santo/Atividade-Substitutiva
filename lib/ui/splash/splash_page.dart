import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/widgets/message_view.dart';
import '../garage/garage_view_model.dart';

/// Tela exibida enquanto os dados locais carregam, ou se a leitura falhar.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final garage = context.watch<GarageViewModel>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: switch (garage.status) {
        GarageStatus.failure => MessageView.error(
          message: garage.loadError?.message ?? 'Falha ao carregar os dados.',
          onRetry: garage.load,
        ),
        _ => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_gas_station_rounded,
                size: 64,
                color: scheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Tanque Cheio',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      },
    );
  }
}
