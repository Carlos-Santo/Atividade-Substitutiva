import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting/formatters.dart';
import '../../domain/models/vehicle.dart';
import '../core/layout/breakpoints.dart';
import '../core/presentation.dart';
import '../core/widgets/confirm_dialog.dart';
import '../core/widgets/constrained_content.dart';
import '../core/widgets/feedback.dart';
import '../garage/garage_view_model.dart';

/// Dados do veículo cadastrado e a opção de excluí-lo.
class VehicleDetailsPage extends StatefulWidget {
  const VehicleDetailsPage({super.key});

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  bool _deleting = false;

  Future<void> _confirmDelete(GarageViewModel garage) async {
    final count = garage.refuelings.length;
    final refuelingsText = switch (count) {
      0 => 'Nenhum abastecimento será afetado.',
      1 => 'O único abastecimento registrado também será excluído.',
      _ => 'Os $count abastecimentos registrados também serão excluídos.',
    };
    final confirmed = await showConfirmDialog(
      context,
      title: 'Excluir veículo?',
      message:
          '${garage.vehicle?.displayName} será removido. $refuelingsText '
          'Essa ação não pode ser desfeita.',
      confirmLabel: 'Excluir tudo',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await garage.deleteVehicle();
      // A tela some (o roteador leva ao cadastro), então o aviso usa o
      // ScaffoldMessenger guardado antes.
      messenger.showSnackBar(
        const SnackBar(content: Text('Veículo e abastecimentos excluídos.')),
      );
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final garage = context.watch<GarageViewModel>();
    final vehicle = garage.vehicle;
    if (vehicle == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Meu veículo')),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          ConstrainedContent(
            maxWidth: ContentWidth.form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _VehicleHeader(vehicle: vehicle),
                const SizedBox(height: 16),
                _VehicleSpecs(
                  vehicle: vehicle,
                  refuelingCount: garage.refuelings.length,
                ),
                const SizedBox(height: 32),
                _DangerZone(
                  deleting: _deleting,
                  onDelete: () => _confirmDelete(garage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  const _VehicleHeader({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              child: Icon(vehicle.type.icon, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.brand.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vehicle.model.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleSpecs extends StatelessWidget {
  const _VehicleSpecs({required this.vehicle, required this.refuelingCount});

  final Vehicle vehicle;
  final int refuelingCount;

  @override
  Widget build(BuildContext context) {
    final liters = Formatters.decimal(
      vehicle.engineDisplacementLiters,
      digits: 1,
    );
    final specs = [
      (Icons.category_rounded, 'Tipo', vehicle.type.label),
      (Icons.calendar_today_rounded, 'Ano', '${vehicle.year}'),
      (
        Icons.speed_rounded,
        'Cilindrada',
        '${Formatters.displacement(vehicle.engineDisplacementCc)} ($liters L)',
      ),
      (
        Icons.local_gas_station_rounded,
        'Abastecimentos',
        '$refuelingCount registrado${refuelingCount == 1 ? '' : 's'}',
      ),
      (Icons.qr_code_rounded, 'Código FIPE do modelo', vehicle.model.code),
    ];

    return Card(
      child: Column(
        children: [
          for (final (i, (icon, label, value)) in specs.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 56),
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                ),
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.deleting, required this.onDelete});

  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Trocar de veículo', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'O app acompanha um veículo por vez. Para cadastrar outro, exclua '
          'o atual. Os abastecimentos dele também serão apagados.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: deleting ? null : onDelete,
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error),
          ),
          icon: deleting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Icon(Icons.delete_outline_rounded),
          label: const Text('Excluir veículo'),
        ),
      ],
    );
  }
}
