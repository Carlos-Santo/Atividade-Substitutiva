import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatting/formatters.dart';
import '../../core/formatting/number_input.dart';
import '../../core/validation/validators.dart';
import '../../domain/models/fuel_type.dart';
import '../../domain/models/refueling.dart';
import '../../domain/models/vehicle_type.dart';
import '../core/layout/breakpoints.dart';
import '../core/presentation.dart';
import '../core/widgets/constrained_content.dart';
import '../core/widgets/feedback.dart';
import '../core/widgets/message_view.dart';
import '../garage/garage_view_model.dart';
import 'refueling_actions.dart';

/// Cadastro e edição de abastecimento.
///
/// Com [refuelingId] nulo cria um registro novo; caso contrário, edita o
/// registro existente.
class RefuelingFormPage extends StatelessWidget {
  const RefuelingFormPage({super.key, this.refuelingId});

  final int? refuelingId;

  @override
  Widget build(BuildContext context) {
    final id = refuelingId;
    if (id == null) return const _RefuelingForm();

    final existing = context.read<GarageViewModel>().findRefueling(id);
    if (existing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const MessageView(
          icon: Icons.search_off_rounded,
          title: 'Abastecimento não encontrado',
          message: 'Ele pode ter sido excluído.',
        ),
      );
    }
    return _RefuelingForm(initial: existing);
  }
}

class _RefuelingForm extends StatefulWidget {
  const _RefuelingForm({this.initial});

  final Refueling? initial;

  @override
  State<_RefuelingForm> createState() => _RefuelingFormState();
}

class _RefuelingFormState extends State<_RefuelingForm> {
  final _formKey = GlobalKey<FormState>();
  final _odometerKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _price;
  late final TextEditingController _liters;
  late final TextEditingController _odometer;
  late FuelType _fuelType;
  late DateTime _date;
  bool _saving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final garage = context.read<GarageViewModel>();
    final last = garage.refuelings.isEmpty ? null : garage.refuelings.last;

    _fuelType =
        initial?.fuelType ??
        last?.fuelType ??
        (garage.vehicle?.type == VehicleType.truck
            ? FuelType.diesel
            : FuelType.gasoline);
    _date = initial?.date ?? _nowWithoutSeconds();
    _price = TextEditingController(
      text: initial == null
          ? ''
          : NumberInput.toEditableText(initial.pricePerLiter),
    );
    _liters = TextEditingController(
      text: initial == null ? '' : NumberInput.toEditableText(initial.liters),
    );
    _odometer = TextEditingController(text: initial?.odometerKm.toString());
  }

  @override
  void dispose() {
    _price.dispose();
    _liters.dispose();
    _odometer.dispose();
    super.dispose();
  }

  static DateTime _nowWithoutSeconds() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }

  double? get _total {
    final price = NumberInput.parseDecimal(_price.text);
    final liters = NumberInput.parseDecimal(_liters.text);
    if (price == null || liters == null || price <= 0 || liters <= 0) {
      return null;
    }
    return Refueling(
      vehicleId: 0,
      fuelType: _fuelType,
      pricePerLiter: price,
      liters: liters,
      odometerKm: 0,
      date: _date,
    ).totalCost;
  }

  String? _validateOdometer(String? text) {
    final basic = Validators.odometer(text);
    if (basic != null) return basic;
    final km = NumberInput.parseInt(text)!;
    final range = context.read<GarageViewModel>().odometerRangeFor(
      _date,
      editingId: widget.initial?.id,
    );
    final previous = range.previous;
    final next = range.next;
    if (previous != null && km <= previous.odometerKm) {
      return 'Deve ser maior que ${Formatters.km(previous.odometerKm)} '
          '(abastecimento de ${Formatters.date(previous.date)})';
    }
    if (next != null && km >= next.odometerKm) {
      return 'Deve ser menor que ${Formatters.km(next.odometerKm)} '
          '(abastecimento de ${Formatters.date(next.date)})';
    }
    return null;
  }

  String? _odometerHelper(GarageViewModel garage) {
    final previous = garage
        .odometerRangeFor(_date, editingId: widget.initial?.id)
        .previous;
    if (previous == null) return 'Valor exibido no painel do veículo';
    return 'Anterior: ${Formatters.km(previous.odometerKm)} '
        'em ${Formatters.date(previous.date)}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Data do abastecimento',
    );
    if (picked == null) return;
    _setDate(
      DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
      helpText: 'Horário do abastecimento',
    );
    if (picked == null) return;
    _setDate(
      DateTime(_date.year, _date.month, _date.day, picked.hour, picked.minute),
    );
  }

  void _setDate(DateTime date) {
    setState(() => _date = date);
    // A faixa válida de km depende da data; revalida se já tem valor.
    if (_odometer.text.isNotEmpty) _odometerKey.currentState?.validate();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final garage = context.read<GarageViewModel>();
    final refueling = Refueling(
      id: widget.initial?.id,
      vehicleId: garage.vehicle!.id!,
      fuelType: _fuelType,
      pricePerLiter: NumberInput.parseDecimal(_price.text)!,
      liters: NumberInput.parseDecimal(_liters.text)!,
      odometerKm: NumberInput.parseInt(_odometer.text)!,
      date: _date,
    );

    setState(() => _saving = true);
    try {
      await garage.saveRefueling(refueling);
      if (!mounted) return;
      context.showSuccess(
        _isEditing ? 'Abastecimento atualizado.' : 'Abastecimento registrado.',
      );
      context.pop();
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final deleted = await confirmAndDeleteRefueling(context, widget.initial!);
    if (deleted && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final garage = context.watch<GarageViewModel>();
    final compact = WindowSize.of(context).isCompact;
    final isFuture = _date.isAfter(DateTime.now());

    final priceField = TextFormField(
      controller: _price,
      decoration: const InputDecoration(
        labelText: 'Preço por litro',
        prefixText: r'R$ ',
        prefixIcon: Icon(Icons.sell_outlined),
        hintText: '5,899',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [NumberInput.decimalFormatter(decimals: 3)],
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: Validators.pricePerLiter,
    );

    final litersField = TextFormField(
      controller: _liters,
      decoration: const InputDecoration(
        labelText: 'Litros abastecidos',
        suffixText: 'L',
        prefixIcon: Icon(Icons.water_drop_outlined),
        hintText: '40,5',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [NumberInput.decimalFormatter(decimals: 3)],
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: Validators.liters,
    );

    final dateField = _PickerField(
      label: 'Data',
      icon: Icons.event_rounded,
      value: Formatters.date(_date),
      onTap: _pickDate,
    );
    final timeField = _PickerField(
      label: 'Horário',
      icon: Icons.schedule_rounded,
      value: Formatters.time(_date),
      onTap: _pickTime,
      errorText: isFuture ? 'Horário no futuro' : null,
    );

    Widget pair(Widget a, Widget b) => compact
        ? Column(children: [a, const SizedBox(height: 16), b])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 16),
              Expanded(child: b),
            ],
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar abastecimento' : 'Novo abastecimento'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Excluir',
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            children: [
              ConstrainedContent(
                maxWidth: ContentWidth.form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionLabel('Combustível'),
                    SegmentedButton<FuelType>(
                      segments: [
                        for (final fuel in FuelType.values)
                          ButtonSegment(
                            value: fuel,
                            label: Text(fuel.label),
                            icon: Icon(fuel.icon),
                          ),
                      ],
                      selected: {_fuelType},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) =>
                          setState(() => _fuelType = selection.first),
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('Quando'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: dateField),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: timeField),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('Valores'),
                    pair(priceField, litersField),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: _odometerKey,
                      controller: _odometer,
                      decoration: InputDecoration(
                        labelText: 'Quilometragem atual',
                        suffixText: 'km',
                        prefixIcon: const Icon(Icons.speed_rounded),
                        helperText: _odometerHelper(garage),
                        errorMaxLines: 2,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [NumberInput.digitsOnly],
                      textInputAction: TextInputAction.done,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: _validateOdometer,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    ListenableBuilder(
                      listenable: Listenable.merge([_price, _liters]),
                      builder: (context, _) => _TotalPreview(total: _total),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving || isFuture ? null : _submit,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _isEditing
                            ? 'Salvar alterações'
                            : 'Registrar abastecimento',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Campo somente leitura que abre um seletor (data ou horário) ao tocar.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      value: value,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            errorText: errorText,
          ),
          child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

class _TotalPreview extends StatelessWidget {
  const _TotalPreview({required this.total});

  final double? total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.payments_outlined, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Valor total',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
            Text(
              total == null ? r'R$ —' : Formatters.currency(total!),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
