import 'package:sqflite/sqflite.dart';

import '../../../core/errors/app_exception.dart';

/// Executa uma operação no banco convertendo erros do SQLite em
/// [StorageException]. Erros que já são [AppException] (como regras de
/// negócio) passam sem alteração.
Future<T> guardStorage<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AppException {
    rethrow;
  } on DatabaseException catch (e) {
    throw StorageException(cause: e);
  }
}
