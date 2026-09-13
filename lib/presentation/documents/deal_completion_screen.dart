import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
import '../../data/models/contract_draft.dart';
import '../../data/models/transaction.dart';
import '../../data/pdf/contract_pdf_font_loader.dart';
import '../../data/pdf/contract_pdf_share_service.dart';
import '../../data/pdf/generated_pdf.dart';
import '../../data/pdf/receipt_pdf_service.dart';
import '../../data/repositories/contractor_profile_repository.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/documents/deal_completion_service.dart';
import '../../domain/documents/receipt.dart';
import '../../domain/profile/contractor_profile.dart';
import '../contracts/contract_pdf_preview_sheet.dart';

/// Экран завершения сделки: автоформирование чека по договору и экспорт PDF.
///
/// Поля чека предзаполняются из профиля ИП и заполненных полей договора, но
/// остаются редактируемыми. По кнопке «Завершить сделку»:
/// 1. при необходимости доход записывается в дашборд (транзакция);
/// 2. чек сохраняется в архив документов;
/// 3. PDF-версия чека генерируется локально и открывается лист предпросмотра.
class DealCompletionScreen extends StatefulWidget {
  final ContractDraft draft;
  final String templateTitle;
  final ContractorProfileRepository profileRepository;
  final DocumentRepository documentRepository;

  /// Репозиторий транзакций. Если задан — доступна запись дохода в дашборд.
  final TransactionRepository? transactionRepository;

  /// Сфера сделки для записи транзакции.
  final TransactionSphere? sphere;

  /// Генератор PDF чека (по умолчанию — встроенный с Roboto).
  final ReceiptPdfGenerator? pdfGenerator;

  /// Загрузчик шрифтов Roboto для PDF (по умолчанию — из Assets).
  final ContractPdfFontLoader? fontLoader;

  /// Сервис шаринга и сохранения PDF (по умолчанию — системный).
  final ContractPdfShareService? shareService;

  /// Позволяет подменить рендер PDF в листе предпросмотра в тестах.
  final Widget Function()? previewBuilder;

  /// Сервис завершения сделки (автоформирование чека).
  final DealCompletionService completionService;

  /// «Сейчас» для предзаполнения даты (для тестов).
  final DateTime? now;

  const DealCompletionScreen({
    super.key,
    required this.draft,
    required this.templateTitle,
    required this.profileRepository,
    required this.documentRepository,
    this.transactionRepository,
    this.sphere,
    this.pdfGenerator,
    this.fontLoader,
    this.shareService,
    this.previewBuilder,
    this.completionService = const DealCompletionService(),
    this.now,
  });

  @override
  State<DealCompletionScreen> createState() => _DealCompletionScreenState();
}

class _DealCompletionScreenState extends State<DealCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceController = TextEditingController();
  final _amountController = TextEditingController();
  final _buyerNameController = TextEditingController();
  final _buyerInnController = TextEditingController();
  final _dateController = TextEditingController();

  late final ContractPdfFontLoader _fontLoader;
  late final ContractPdfShareService _shareService;
  late final Map<String, String> _contractFields;

  ContractorProfile? _profile;
  bool _loading = true;
  bool _busy = false;
  bool _recordIncome = true;

  @override
  void initState() {
    super.initState();
    _fontLoader = widget.fontLoader ?? const ContractPdfFontLoader();
    _shareService = widget.shareService ?? const ContractPdfShareService();
    _contractFields = contractFieldsToMap(widget.draft.filledFields);
    _recordIncome = widget.transactionRepository != null;
    _initialize();
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _amountController.dispose();
    _buyerNameController.dispose();
    _buyerInnController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final profile = await widget.profileRepository.load();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
    if (profile == null) return;
    _prefill(profile);
  }

  /// Автозаполняет поля чека реквизитами из профиля ИП и договора.
  void _prefill(ContractorProfile profile) {
    final receipt = const ReceiptGenerator().generate(
      profile: profile,
      contractFields: _contractFields,
      contractDraftId: widget.draft.id,
      date: widget.now,
    );
    _serviceController.text = receipt.serviceName;
    _amountController.text = receipt.amount.toStringAsFixed(2);
    _buyerNameController.text = receipt.buyerName;
    _buyerInnController.text = receipt.buyerInn;
    _dateController.text = receipt.formattedDate;
  }

  String get _contractNumber =>
      _contractFields[ContractFieldKeys.contractNumber] ?? '';

  Future<GeneratedPdf> _generatePdf(Receipt receipt, String fileName) async {
    final generator = widget.pdfGenerator;
    if (generator != null) return generator(receipt, fileName);
    final fonts = await _fontLoader.load();
    return const ReceiptPdfService().generateInBackground(
      receipt: receipt,
      fonts: fonts,
      fileName: fileName,
    );
  }

  String _pdfFileName() {
    final raw = _contractNumber.trim().isEmpty
        ? _dateController.text
        : _contractNumber;
    final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    return 'receipt_${safe.isEmpty ? 'untitled' : safe}.pdf';
  }

  Future<void> _completeDeal() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? true)) return;

    final profile = _profile;
    if (profile == null) {
      _showSnack('Профиль ИП не заполнен');
      return;
    }

    setState(() => _busy = true);
    try {
      final amount = parseReceiptAmount(_amountController.text);
      final date =
          parseContractDate(_dateController.text) ??
          widget.now ??
          DateTime.now();

      var transactionId = 0;
      if (_recordIncome && widget.transactionRepository != null) {
        final transaction = Transaction(
          amount: amount,
          date: date,
          sphere: widget.sphere ?? TransactionSphere.it,
          clientName: _buyerNameController.text.trim(),
          clientInn: _buyerInnController.text.trim(),
        );
        transactionId = await widget.transactionRepository!.add(transaction);
      }

      final receipt = Receipt(
        sellerName: profile.fullName,
        sellerInn: profile.inn,
        serviceName: _serviceController.text.trim(),
        amount: amount,
        date: date,
        buyerName: _buyerNameController.text.trim(),
        buyerInn: _buyerInnController.text.trim(),
        contractDraftId: widget.draft.id,
        contractNumber: _contractNumber,
        transactionId: transactionId,
      );

      final completed = await widget.completionService.saveReceipt(
        receipt: receipt,
        documentRepository: widget.documentRepository,
      );

      final pdf = await _generatePdf(completed.receipt, _pdfFileName());
      if (!mounted) return;
      setState(() => _busy = false);
      await showContractPdfPreviewSheet(
        context,
        pdf: pdf,
        shareService: _shareService,
        previewBuilder: widget.previewBuilder,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showSnack('Не удалось завершить сделку. Попробуйте ещё раз.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Завершение сделки')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _buildContractCard(theme),
                    const SizedBox(height: 16),
                    Text('Данные чека', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Реквизиты подставлены из профиля ИП и договора. '
                      'При необходимости отредактируйте их.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('receipt_service_field'),
                      controller: _serviceController,
                      validator: _required('Укажите наименование услуги'),
                      decoration: const InputDecoration(
                        labelText: 'Наименование услуги',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('receipt_amount_field'),
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _amountValidator,
                      decoration: const InputDecoration(
                        labelText: 'Сумма, ₽',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('receipt_buyer_name_field'),
                      controller: _buyerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Покупатель (заказчик)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('receipt_buyer_inn_field'),
                      controller: _buyerInnController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ИНН покупателя',
                        helperText: 'Необязательно для физлиц',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('receipt_date_field'),
                      controller: _dateController,
                      validator: _dateValidator,
                      decoration: const InputDecoration(
                        labelText: 'Дата расчёта',
                        helperText: 'Формат ДД.ММ.ГГГГ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (widget.transactionRepository != null) ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        key: const Key('receipt_record_income_switch'),
                        value: _recordIncome,
                        onChanged: _busy
                            ? null
                            : (value) => setState(() => _recordIncome = value),
                        title: const Text('Добавить доход в дашборд'),
                        subtitle: const Text(
                          'Сделка появится в списке транзакций',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('complete_deal_button'),
                      onPressed: _busy ? null : _completeDeal,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.receipt_long_outlined),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _busy ? 'Формирование чека…' : 'Завершить сделку',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildContractCard(ThemeData theme) {
    final client = _contractFields[ContractFieldKeys.clientName] ?? '';
    final amount = _contractFields[ContractFieldKeys.amount] ?? '';
    final subtitle = [
      if (client.isNotEmpty) client,
      if (_contractNumber.isNotEmpty) '№ $_contractNumber',
      if (amount.isNotEmpty) '$amount ₽',
    ].join(' · ');

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.templateTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  static String? Function(String?) _required(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) return message;
      return null;
    };
  }

  static String? _amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Укажите сумму';
    if (parseReceiptAmount(value) <= 0) return 'Сумма должна быть больше нуля';
    return null;
  }

  static String? _dateValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Укажите дату расчёта';
    if (parseContractDate(value) == null) return 'Формат даты: ДД.ММ.ГГГГ';
    return null;
  }
}
