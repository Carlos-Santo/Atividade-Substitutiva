/// Escolhe a implementação do SQLite conforme a plataforma:
/// * Android e iOS: plugin nativo `sqflite`;
/// * Windows, Linux e macOS: `sqflite_common_ffi`;
/// * Web: `sqflite_common_ffi_web` (SQLite em WebAssembly, salvo no
///   IndexedDB do navegador).
library;

export 'database_factory_io.dart'
    if (dart.library.js_interop) 'database_factory_web.dart';
