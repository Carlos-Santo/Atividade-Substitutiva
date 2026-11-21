import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting/formatters.dart';
import '../../domain/models/refueling.dart';
import '../core/widgets/confirm_dialog.dart';
import '../core/widgets/feedback.dart';
import '../garage/garage_view_model.dart';

/// Pede confirmação e exclui o abastecimento. Retorna `true` se excluiu.
///
/// Fica separado porque é usado na lista e na tela de edição.
Future<bool> confirmAndDeleteRefueling(
  BuildContext context,
  Refueling refueling,
) async {
  final garage = context.read<GarageViewModel>();
  final confirmed = await showConfirmDialog(
    context,
    title: 'Excluir abastecimento?',
    message:
        'O abastecimento de ${Formatters.dateTime(refueling.date)} '
        '(${Formatters.currency(refueling.totalCost)}) será removido e os '
        'indicadores serão recalculados.',
  );
  if (!confirmed || !context.mounted) return false;

  try {
    await garage.deleteRefueling(refueling.id!);
    if (context.mounted) context.showSuccess('Abastecimento excluído.');
    return true;
  } catch (e) {
    if (context.mounted) context.showError(e);
    return false;
  }
}
