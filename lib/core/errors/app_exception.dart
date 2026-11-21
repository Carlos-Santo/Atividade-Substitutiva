/// Erros esperados do app, já com uma mensagem pronta para o usuário.
///
/// As camadas de dados convertem falhas técnicas (HTTP, SQLite) nestes tipos,
/// e a interface só precisa exibir [message].
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;

  /// Erro original, útil para logs e depuração.
  final Object? cause;

  @override
  String toString() =>
      '$runtimeType: $message${cause == null ? '' : ' ($cause)'}';
}

/// Sem conexão, tempo esgotado ou falha de rede.
final class NetworkException extends AppException {
  const NetworkException({super.cause})
    : super(
        'Não foi possível conectar à internet. '
        'Verifique sua conexão e tente novamente.',
      );
}

/// A API respondeu com erro ou com um formato inesperado.
final class ApiException extends AppException {
  const ApiException({this.statusCode, super.cause})
    : super(
        'O serviço de consulta de veículos está indisponível no momento. '
        'Tente novamente em instantes.',
      );

  final int? statusCode;
}

/// Falha ao ler ou gravar no banco de dados local.
final class StorageException extends AppException {
  const StorageException({super.cause})
    : super('Não foi possível salvar os dados no aparelho.');
}

/// Violação de uma regra de negócio, como cadastrar um segundo veículo.
final class BusinessRuleException extends AppException {
  const BusinessRuleException(super.message);
}
