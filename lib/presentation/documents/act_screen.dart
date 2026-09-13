import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
import '../../data/models/contract_draft.dart';
import '../../data/models/document.dart';
import '../../data/pdf/act_pdf_service.dart';
import '../../data/pdf/contract_pdf_font_loader.dart';
import '../../data/pdf/contract_pdf_share_service.dart';
import '../../data/pdf/generated_pdf.dart';
import '../../data/repositories/contractor_profile_repository.dart';
import '../../data/repositories/document_repository.dart';
import '../../domain/documents/act.dart';
import '../../domain/documents/act_service.dart';
import '../../domain/documents/receipt.dart';
import '../../domain/profile/contractor_profile.dart';
import '../contracts/contract_pdf_preview_sheet.dart';
import 'document_card.dart';

/// Экран акта выполненных работ: автозаполнение из договора и чека,
/// автосохранение черновика и экспорт PDF с подписями сторон.
///
/// Поля акта предзаполняются из профиля ИП, договора и последнего чека по
/// этому договору. Любое изменение поля автоматически сохраняется в архив
/// документов (черновик). По кнопке «Сформировать акт» документ переводится
/// в статус «Сформирован», PDF генерируется локально и открывается лист
/// предпросмотра.
class ActScreen extends StatefulWidget {
  final ContractDraft draft;
  final String templateTitle;
  final ContractorProfileRepository profileRepository;
  final DocumentRepository documentRepository;

  /// Генератор PDF акта (по умолчанию — встроенный с Roboto).
  final ActPdfGenerator? pdfGenerator;

  /// Загрузчик шрифтов Roboto для PDF (по умолчанию — из Assets).
  final ContractPdfFontLoader? fontLoader;

  /// Сервис шаринга и сохранения PDF (по умолчанию — системный).
  final ContractPdfShareService? shareService;

  /// Позволяет подменить рендер PDF в листе предпросмотра в тестах.
  final Widget Function()? previewBuilder;

  /// Сервис сохранения акта.
  final ActService actService;

  /// Задержка автосохранения после изменения поля.
  final Duration autosaveDebounce;

  /// «Сейчас» для предзаполнения даты (для тестов).
  final DateTime? now;

  const ActScreen({
    super.key,
    required this.draft,
    required this.templateTitle,
    required this.profileRepository,
    required this.documentRepository,
    this.pdfGenerator,
    this.fontLoader,
    this.shareService,
    this.previewBuilder,
    this.actService = const ActService(),
    this.autosaveDebounce = const Duration(milliseconds: 800),
    this.now,
  });

  @override
  State<ActScreen> createState() => _ActScreenState();
}

class _ActScreenState extends State<ActScreen> {
  final _formKey = GlobalKey<FormState>();
  final _worksController = TextEditingController();
  final _resultController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _executorSignatoryController = TextEditingController();
  final _customerSignatoryController = TextEditingController();

  late final ContractPdfFontLoader _fontLoader;
  late final ContractPdfShareService _shareService;
  late final Map<String, String> _contractFields;

  ContractorProfile? _profile;
  Receipt? _receipt;
  Document? _receiptDocument;

  /// Идентификатор сохранённого черновика акта в архиве (`0` — не сохранён).
  int _documentId = 0;

  /// Последняя сохранённая запись архива (для карточки документа).
  Document? _document;

  Timer? _autosaveTimer;
  bool _loading = true;
  bool _busy = false;
  bool _saving = false;
  bool _dirty = false;
  bool _autosaveReady = false;

  @override
  void initState() {
    super.initState();
    _fontLoader = widget.fontLoader ?? const ContractPdfFontLoader();
    _shareService = widget.shareService ?? const ContractPdfShareService();
    _contractFields = contractFieldsToMap(widget.draft.filledFields);
    for (final controller in _controllers) {
      controller.addListener(_onFieldChanged);
    }
    _initialize();
  }

  List<TextEditingController> get _controllers => [
    _worksController,
    _resultController,
    _amountController,
    _dateController,
    _executorSignatoryController,
    _customerSignatoryController,
  ];

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    for (final controller in _controllers) {
      controller.removeListener(_onFieldChanged);
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    final profile = await widget.profileRepository.load();
    final linked = await widget.documentRepository.getByContractDraftId(
      widget.draft.id,
    );
    final receiptDocument = linked
        .where((d) => d.type == DocumentType.receipt)
        .fold<Document?>(null, (latest, d) {
          if (latest == null || d.date.isAfter(latest.date)) return d;
          return latest;
        });

    if (!mounted) return;
    _profile = profile;
    _receiptDocument = receiptDocument;
    _receipt = receiptDocument == null
        ? null
        : Receipt.fromDocument(receiptDocument);
    setState(() => _loading = false);
    if (profile == null) return;
    _prefill(profile);
    _autosaveReady = true;
    // Автосохранение при создании документа: черновик сразу попадает в архив.
    _dirty = true;
    await _autosave();
  }

  /// Автозаполняет поля акта реквизитами из профиля ИП, договора и чека.
  void _prefill(ContractorProfile profile) {
    final act = const ActGenerator().generate(
      profile: profile,
      contractFields: _contractFields,
      receipt: _receipt,
      contractDraftId: widget.draft.id,
      receiptDocumentId: _receiptDocument?.id ?? 0,
      completionDate: widget.now,
    );
    _worksController.text = act.worksDescription;
    _resultController.text = act.result;
    _amountController.text = act.amount.toStringAsFixed(2);
    _dateController.text = act.formattedDate;
    _executorSignatoryController.text = act.executorSignatory;
    _customerSignatoryController.text = act.customerSignatory;
  }

  String get _contractNumber =>
      _contractFields[ContractFieldKeys.contractNumber] ?? '';

  /// Собирает доменную модель акта из текущих значений полей.
  Act? _buildAct() {
    final profile = _profile;
    if (profile == null) return null;
    final amount = parseReceiptAmount(_amountController.text);
    final date =
        parseContractDate(_dateController.text) ??
        widget.now ??
        DateTime.now();
    return Act(
      sellerName: profile.fullName,
      sellerInn: profile.inn,
      worksDescription: _worksController.text.trim(),
      amount: amount,
      completionDate: date,
      buyerName: _contractFields[ContractFieldKeys.clientName] ?? '',
      buyerInn: _contractFields[ContractFieldKeys.clientInn] ?? '',
      result: _resultController.text.trim(),
      contractDraftId: widget.draft.id,
      contractNumber: _contractNumber,
      receiptDocumentId: _receiptDocument?.id ?? 0,
      executorSignatory: _executorSignatoryController.text.trim(),
      customerSignatory: _customerSignatoryController.text.trim(),
    );
  }

  void _onFieldChanged() {
    if (!_autosaveReady) return;
    _dirty = true;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(widget.autosaveDebounce, _autosave);
    if (mounted) setState(() {});
  }

  Future<void> _autosave() async {
    if (_saving || !_dirty) return;
    final act = _buildAct();
    if (act == null) return;
    setState(() => _saving = true);
    try {
      final saved = await widget.actService.save(
        act: act,
        documentRepository: widget.documentRepository,
        documentId: _documentId,
        status: DocumentStatus.draft,
      );
      _documentId = saved.document.id;
      _document = saved.document;
      _dirty = false;
      if (mounted) setState(() => _saving = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('Не удалось автосохранить акт');
    }
  }

  Future<GeneratedPdf> _generatePdf(Act act, String fileName) async {
    final generator = widget.pdfGenerator;
    if (generator != null) return generator(act, fileName);
    final fonts = await _fontLoader.load();
    return const ActPdfService().generateInBackground(
      act: act,
      fonts: fonts,
      fileName: fileName,
    );
  }

  String _pdfFileName() {
    final raw = _contractNumber.trim().isEmpty
        ? _dateController.text
        : _contractNumber;
    final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    return 'act_${safe.isEmpty ? 'untitled' : safe}.pdf';
  }

  Future<void> _finalize() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? true)) return;

    final act = _buildAct();
    if (act == null) {
      _showSnack('Профиль ИП не заполнен');
      return;
    }

    _autosaveTimer?.cancel();
    setState(() => _busy = true);
    try {
      final saved = await widget.actService.save(
        act: act,
        documentRepository: widget.documentRepository,
        documentId: _documentId,
        status: DocumentStatus.generated,
      );
      _documentId = saved.document.id;
      _document = saved.document;

      final pdf = await _generatePdf(act, _pdfFileName());
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
      _showSnack('Не удалось сформировать акт. Попробуйте ещё раз.');
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
      appBar: AppBar(
        title: const Text('Акт выполненных работ'),
        actions: [_buildAutosaveIndicator()],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _buildContractCard(theme),
                    if (_document != null) ...[
                      const SizedBox(height: 16),
                      DocumentCard(
                        document: _document!,
                        linkedContractNumber: _contractNumber,
                        linkedReceipt: _receiptDocument,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text('Данные акта', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Поля подставлены из договора и чека. При необходимости '
                      'отредактируйте их — изменения сохраняются автоматически.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('act_works_field'),
                      controller: _worksController,
                      maxLines: 2,
                      validator: _required('Укажите описание работ'),
                      decoration: const InputDecoration(
                        labelText: 'Описание работ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('act_result_field'),
                      controller: _resultController,
                      maxLines: 3,
                      validator: _required('Укажите результат работ'),
                      decoration: const InputDecoration(
                        labelText: 'Результат работ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('act_amount_field'),
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
                      key: const Key('act_date_field'),
                      controller: _dateController,
                      validator: _dateValidator,
                      decoration: const InputDecoration(
                        labelText: 'Дата выполнения работ',
                        helperText: 'Формат ДД.ММ.ГГГГ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Подписи сторон', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Поля для распечатки: ФИО или должность подписантов.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('act_executor_signatory_field'),
                      controller: _executorSignatoryController,
                      decoration: const InputDecoration(
                        labelText: 'Исполнитель (подпись)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('act_customer_signatory_field'),
                      controller: _customerSignatoryController,
                      decoration: const InputDecoration(
                        labelText: 'Заказчик (подпись)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const Key('act_finalize_button'),
                      onPressed: _busy ? null : _finalize,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.assignment_turned_in_outlined),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _busy ? 'Формирование акта…' : 'Сформировать акт',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAutosaveIndicator() {
    final label = _saving
        ? 'Сохранение…'
        : (_dirty ? 'Не сохранено' : 'Сохранено');
    return Padding(
      key: const Key('act_autosave_indicator'),
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_saving)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.cloud_done_outlined, size: 16),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildContractCard(ThemeData theme) {
    final client = _contractFields[ContractFieldKeys.clientName] ?? '';
    final subtitle = [
      if (client.isNotEmpty) client,
      if (_contractNumber.isNotEmpty) '№ $_contractNumber',
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
                Icon(
                  Icons.description_outlined,
                  color: theme.colorScheme.primary,
                ),
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
            if (_receiptDocument != null) ...[
              const SizedBox(height: 4),
              Text(
                'Чек привязан: от '
                '${formatContractDate(_receiptDocument!.date)}',
                key: const Key('act_receipt_link_hint'),
                style: theme.textTheme.bodySmall,
              ),
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
    if (value == null || value.trim().isEmpty) {
      return 'Укажите дату выполнения работ';
    }
    if (parseContractDate(value) == null) return 'Формат даты: ДД.ММ.ГГГГ';
    return null;
  }
}
