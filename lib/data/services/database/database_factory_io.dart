import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool get _isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

DatabaseFactory createDatabaseFactory() {
  if (_isDesktop) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return sqflite.databaseFactory;
}

/// Pasta onde o arquivo do banco fica salvo.
Future<String> databaseDirectory(DatabaseFactory factory) async {
  if (_isDesktop) return (await getApplicationSupportDirectory()).path;
  return factory.getDatabasesPath();
}
