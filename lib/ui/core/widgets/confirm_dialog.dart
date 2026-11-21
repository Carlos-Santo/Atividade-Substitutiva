import 'package:flutter/material.dart';

/// Diálogo de confirmação para ações destrutivas.
///
/// Retorna `true` só quando o usuário confirma.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Excluir',
  IconData icon = Icons.delete_forever_rounded,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        icon: Icon(icon, color: scheme.error),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              minimumSize: const Size(64, 44),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
