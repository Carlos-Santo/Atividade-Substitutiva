import '../../core/errors/app_exception.dart';

/// Estado de um dado carregado de forma assíncrona (por exemplo, da API).
///
/// Por ser `sealed`, o `switch` sobre ele obriga a tratar todos os casos.
sealed class LoadState<T> {
  const LoadState();

  T? get dataOrNull => switch (this) {
    Loaded<T>(:final data) => data,
    _ => null,
  };

  bool get isLoading => this is Loading<T>;
}

/// Ainda não foi solicitado (por exemplo, modelos antes de escolher a marca).
final class Idle<T> extends LoadState<T> {
  const Idle();
}

final class Loading<T> extends LoadState<T> {
  const Loading();
}

final class Loaded<T> extends LoadState<T> {
  const Loaded(this.data);
  final T data;
}

final class LoadFailed<T> extends LoadState<T> {
  const LoadFailed(this.error);
  final AppException error;
}
