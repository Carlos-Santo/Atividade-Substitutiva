import 'package:flutter/material.dart';

import '../../../core/errors/app_exception.dart';

/// Mensagens rápidas (SnackBar) padronizadas.
extension FeedbackContext on BuildContext {
  void showSuccess(String message) => _show(message, isError: false);

  void showError(Object error) => _show(
    error is AppException
        ? error.message
        : 'Ocorreu um erro inesperado. Tente novamente.',
    isError: true,
  );

  void _show(String message, {required bool isError}) {
    final scheme = Theme.of(this).colorScheme;
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? scheme.error : null,
        ),
      );
  }
}
