import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatting/formatters.dart';
import '../core/layout/breakpoints.dart';
import '../core/widgets/constrained_content.dart';
import '../core/widgets/message_view.dart';
import '../garage/garage_view_model.dart';
import '../routing/routes.dart';
import 'refueling_actions.dart';
import 'widgets/refueling_card.dart';

/// Histórico de abastecimentos, do mais recente para o mais antigo.
class RefuelingListPage extends StatelessWidget {
  const RefuelingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final garage = context.watch<GarageViewModel>();
    final report = garage.report;
    final entries = report.newestFirst.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Abastecimentos')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'refuelings-fab',
        onPressed: () => context.push(Routes.newRefueling),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Abastecer'),
      ),
      body: entries.isEmpty
          ? MessageView(
              icon: Icons.local_gas_station_rounded,
              title: 'Nenhum abastecimento ainda',
              message:
                  'Registre o primeiro abastecimento com o tanque cheio. '
                  'Ele será a referência para calcular o consumo.',
              action: FilledButton.icon(
                onPressed: () => context.push(Routes.newRefueling),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Registrar abastecimento'),
              ),
            )
          : ListView.separated(
              // Espaço extra no fim para o botão flutuante não cobrir o card.
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: entries.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ConstrainedContent(
                    maxWidth: ContentWidth.form,
                    child: Text(
                      '${report.count} registro${report.count == 1 ? '' : 's'} · '
                      '${Formatters.currency(report.totalSpent)} no total',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                final insight = entries[index - 1];
                final refueling = insight.refueling;
                return ConstrainedContent(
                  maxWidth: ContentWidth.form,
                  child: RefuelingCard(
                    key: ValueKey(refueling.id),
                    insight: insight,
                    onAction: (action) => switch (action) {
                      RefuelingAction.edit => context.push(
                        Routes.editRefueling(refueling.id!),
                      ),
                      RefuelingAction.delete => confirmAndDeleteRefueling(
                        context,
                        refueling,
                      ),
                    },
                  ),
                );
              },
            ),
    );
  }
}
