import 'package:intl/intl.dart';

/// Formatação de valores no padrão brasileiro (pt-BR).
///
/// Centralizar aqui garante o mesmo formato em todas as telas.
abstract final class Formatters {
  static const _locale = 'pt_BR';

  static final _currency = NumberFormat.currency(
    locale: _locale,
    symbol: r'R$',
  );
  static final _pricePerLiter = NumberFormat.currency(
    locale: _locale,
    symbol: r'R$',
    decimalDigits: 3,
  );
  static final _integer = NumberFormat.decimalPattern(_locale);
  static final _date = DateFormat('dd/MM/yyyy', _locale);
  static final _shortDate = DateFormat('dd/MM', _locale);
  static final _compactDate = DateFormat('dd/MM/yy', _locale);
  static final _time = DateFormat('HH:mm', _locale);
  static final _dateTime = DateFormat("dd/MM/yyyy 'às' HH:mm", _locale);

  static NumberFormat _decimal(int digits) =>
      NumberFormat.decimalPatternDigits(locale: _locale, decimalDigits: digits);

  /// R$ 1.234,56
  static String currency(double value) => _currency.format(value);

  /// R$ 5,899
  static String pricePerLiter(double value) => _pricePerLiter.format(value);

  /// R$ 0,52/km
  static String costPerKm(double value) => '${_currency.format(value)}/km';

  /// 12,4 km/L
  static String kmPerLiter(double value) => '${_decimal(1).format(value)} km/L';

  /// 45.200
  static String integer(int value) => _integer.format(value);

  /// 45.200 km
  static String km(int value) => '${_integer.format(value)} km';

  /// 40,5 L (até 2 casas, sem zeros desnecessários)
  static String liters(double value) {
    final format = NumberFormat.decimalPattern(_locale)
      ..maximumFractionDigits = 2;
    return '${format.format(value)} L';
  }

  /// 1.598 cm³
  static String displacement(int cc) => '${_integer.format(cc)} cm³';

  /// Número decimal com [digits] casas, por exemplo 12,35.
  static String decimal(double value, {int digits = 2}) =>
      _decimal(digits).format(value);

  static String date(DateTime value) => _date.format(value);
  static String shortDate(DateTime value) => _shortDate.format(value);
  static String compactDate(DateTime value) => _compactDate.format(value);
  static String time(DateTime value) => _time.format(value);
  static String dateTime(DateTime value) => _dateTime.format(value);
}
