import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Configuração global dos testes: carrega os formatos pt-BR, como o
/// `main.dart` faz no app real.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');
  await testMain();
}
