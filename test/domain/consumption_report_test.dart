import 'package:flutter_test/flutter_test.dart';
import 'package:tanque_cheio/domain/models/consumption_report.dart';
import 'package:tanque_cheio/domain/models/refueling_insight.dart';

import '../helpers/fakes.dart';

void main() {
  group('RefuelingInsight', () {
    test('primeiro abastecimento é só referência, sem indicadores', () {
      final insight = RefuelingInsight(
        refueling: refuelingAt(km: 1000, liters: 40, date: DateTime(2026)),
      );

      expect(insight.isBaseline, isTrue);
      expect(insight.hasIndicators, isFalse);
      expect(insight.distanceKm, isNull);
      expect(insight.kmPerLiter, isNull);
      expect(insight.costPerKm, isNull);
    });

    test('calcula distância, km/L e R\$/km conforme o enunciado', () {
      final previous = refuelingAt(km: 10000, liters: 40, date: DateTime(2026));
      final current = refuelingAt(
        km: 10500,
        liters: 40,
        price: 6.0,
        date: DateTime(2026, 1, 10),
      );
      final insight = RefuelingInsight(refueling: current, previous: previous);

      // distância = 10500 - 10000
      expect(insight.distanceKm, 500);
      // km/L = 500 / 40 litros do abastecimento atual
      expect(insight.kmPerLiter, closeTo(12.5, 1e-9));
      // R$/km = (6,00 × 40) / 500
      expect(insight.costPerKm, closeTo(0.48, 1e-9));
    });

    test('distância não positiva não gera indicadores', () {
      final insight = RefuelingInsight(
        refueling: refuelingAt(km: 1000, liters: 30, date: DateTime(2026, 2)),
        previous: refuelingAt(km: 1000, liters: 30, date: DateTime(2026)),
      );
      expect(insight.hasIndicators, isFalse);
      expect(insight.kmPerLiter, isNull);
    });
  });

  group('ConsumptionReport', () {
    final history = [
      // Fora de ordem de propósito: o relatório deve ordenar por data.
      refuelingAt(
        id: 3,
        km: 10900,
        liters: 30,
        price: 6,
        date: DateTime(2026, 3),
      ),
      refuelingAt(id: 1, km: 10000, liters: 45, date: DateTime(2026)),
      refuelingAt(id: 2, km: 10500, liters: 40, date: DateTime(2026, 2)),
    ];

    test('ordena cronologicamente e liga cada registro ao anterior', () {
      final report = ConsumptionReport.from(history);

      expect(report.entries.map((e) => e.refueling.id), [1, 2, 3]);
      expect(report.entries.first.isBaseline, isTrue);
      expect(report.entries[1].previous?.id, 1);
      expect(report.entries[2].previous?.id, 2);
      expect(report.newestFirst.first.refueling.id, 3);
      expect(report.latest?.refueling.id, 3);
    });

    test('totaliza valores, litros e distância', () {
      final report = ConsumptionReport.from(history);

      expect(report.count, 3);
      expect(report.totalSpent, closeTo(225 + 200 + 180, 1e-9));
      expect(report.totalLiters, closeTo(115, 1e-9));
      expect(report.totalDistanceKm, 900);
      expect(report.averageRefuelingCost, closeTo(605 / 3, 1e-9));
      expect(report.measured, hasLength(2));
    });

    test('médias são ponderadas e ignoram os litros da referência', () {
      final report = ConsumptionReport.from(history);

      // 900 km ÷ (40 + 30) litros
      expect(report.averageKmPerLiter, closeTo(900 / 70, 1e-9));
      // (200 + 180) reais ÷ 900 km
      expect(report.averageCostPerKm, closeTo(380 / 900, 1e-9));
    });

    test('com um único registro não há médias de consumo', () {
      final report = ConsumptionReport.from([history.first]);

      expect(report.averageKmPerLiter, isNull);
      expect(report.averageCostPerKm, isNull);
      expect(report.totalDistanceKm, 0);
      expect(report.totalSpent, closeTo(180, 1e-9));
    });

    test('relatório vazio', () {
      final report = ConsumptionReport.from(const []);

      expect(report.isEmpty, isTrue);
      expect(report.latest, isNull);
      expect(report.averageRefuelingCost, isNull);
      expect(report.totalSpent, 0);
    });
  });
}
