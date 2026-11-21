import 'package:flutter_test/flutter_test.dart';
import 'package:tanque_cheio/ui/dashboard/widgets/chart_point.dart';

void main() {
  test('reconhece datas do mesmo dia, ignorando o horário', () {
    expect(
      ChartScale.sameDay(DateTime(2026, 11, 20, 8), DateTime(2026, 11, 20, 23)),
      isTrue,
    );
    expect(
      ChartScale.sameDay(DateTime(2026, 11, 20), DateTime(2026, 11, 21)),
      isFalse,
    );
    expect(
      ChartScale.sameDay(DateTime(2025, 11, 20), DateTime(2026, 11, 20)),
      isFalse,
    );
  });

  test('intervalo dos rótulos limita a quantidade exibida', () {
    expect(ChartScale.labelInterval(4), 1);
    expect(ChartScale.labelInterval(8), 2);
    expect(ChartScale.labelInterval(30), 5);
  });

  test('faixa do eixo Y tem folga e não fica negativa', () {
    final range = ChartScale.paddedRange([10, 14]);
    expect(range.min, lessThan(10));
    expect(range.max, greaterThan(14));
    expect(ChartScale.paddedRange([0.1, 0.2]).min, greaterThanOrEqualTo(0));
  });
}
