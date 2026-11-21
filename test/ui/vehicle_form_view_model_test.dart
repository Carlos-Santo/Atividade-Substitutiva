import 'package:flutter_test/flutter_test.dart';
import 'package:tanque_cheio/core/errors/app_exception.dart';
import 'package:tanque_cheio/domain/models/vehicle_type.dart';
import 'package:tanque_cheio/ui/core/load_state.dart';
import 'package:tanque_cheio/ui/vehicle/vehicle_form_view_model.dart';

import '../helpers/fakes.dart';

void main() {
  test('carrega marcas e depois os modelos da marca escolhida', () async {
    final catalog = FakeCatalogRepository();
    final form = VehicleFormViewModel(catalog);

    await form.loadBrands();
    expect(
      form.brands.dataOrNull,
      FakeCatalogRepository.brands[VehicleType.car],
    );
    expect(form.models, isA<Idle<Object>>());

    form.selectBrand(FakeCatalogRepository.fiat);
    await pumpEventQueue();

    expect(catalog.modelRequests, ['21']);
    expect(form.models.dataOrNull, [
      FakeCatalogRepository.argo,
      FakeCatalogRepository.mobi,
    ]);
  });

  test('trocar a marca limpa o modelo escolhido', () async {
    final form = VehicleFormViewModel(FakeCatalogRepository());
    await form.loadBrands();
    form.selectBrand(FakeCatalogRepository.fiat);
    await pumpEventQueue();
    form.selectModel(FakeCatalogRepository.argo);
    expect(form.suggestedDisplacementCc, 1300);

    form.selectBrand(FakeCatalogRepository.vw);

    expect(form.model, isNull);
    expect(form.suggestedDisplacementCc, isNull);
  });

  test('trocar o tipo recarrega as marcas e limpa as escolhas', () async {
    final catalog = FakeCatalogRepository();
    final form = VehicleFormViewModel(catalog);
    await form.loadBrands();
    form.selectBrand(FakeCatalogRepository.fiat);
    await pumpEventQueue();

    form.selectType(VehicleType.motorcycle);
    await pumpEventQueue();

    expect(form.brand, isNull);
    expect(form.model, isNull);
    expect(form.models, isA<Idle<Object>>());
    expect(catalog.brandRequests.last, VehicleType.motorcycle);
    expect(form.brands.dataOrNull, [FakeCatalogRepository.honda]);
  });

  test('resposta atrasada de uma marca antiga é descartada', () async {
    final catalog = FakeCatalogRepository(manual: true);
    final form = VehicleFormViewModel(catalog);

    form.selectBrand(FakeCatalogRepository.fiat);
    form.selectBrand(FakeCatalogRepository.vw);
    expect(form.models.isLoading, isTrue);

    // A resposta da VW chega primeiro; a da Fiat chega depois.
    catalog.complete('models/59');
    await pumpEventQueue();
    catalog.complete('models/21');
    await pumpEventQueue();

    expect(form.models.dataOrNull, [FakeCatalogRepository.gol]);
  });

  test('erro da API fica disponível para a tela', () async {
    final catalog = FakeCatalogRepository()
      ..failBrandsWith = const NetworkException();
    final form = VehicleFormViewModel(catalog);

    await form.loadBrands();

    expect(form.brands, isA<LoadFailed<Object>>());
  });

  test('monta o veículo apenas com marca e modelo escolhidos', () async {
    final form = VehicleFormViewModel(FakeCatalogRepository());
    expect(form.buildVehicle(year: 2022, displacementCc: 1300), isNull);

    await form.loadBrands();
    form.selectBrand(FakeCatalogRepository.fiat);
    await pumpEventQueue();
    form.selectModel(FakeCatalogRepository.argo);

    expect(form.buildVehicle(year: 2022, displacementCc: 1300), unsavedVehicle);
  });
}
