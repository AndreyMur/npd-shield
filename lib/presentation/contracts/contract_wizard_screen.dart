import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/contract_field_keys.dart';
import '../../../core/validation/contract_input.dart';
import '../../../data/models/contract_draft.dart';
import '../../../data/models/contract_template.dart';
import '../../../data/pdf/contract_pdf_font_loader.dart';
import '../../../data/pdf/contract_pdf_service.dart';
import '../../../data/pdf/contract_pdf_share_service.dart';
import '../../../data/repositories/contract_draft_repository.dart';
import '../../../data/repositories/contract_template_text_loader.dart';
import '../../../data/repositories/contractor_profile_repository.dart';
import '../../../domain/contracts/contract_document.dart';
import '../../../domain/profile/contractor_profile.dart';
import 'contract_document_preview.dart';
import 'contract_pdf_preview_sheet.dart';
import 'template_sphere_visuals.dart';

/// Сигнатура функции генерации PDF, переопределяемой в тестах.
typedef ContractPdfGenerator =
    Future<GeneratedContractPdf> Function(
      ComposedContract document,
      String fileName,
    );

/// Переход к следующему шагу (Ctrl/Cmd+Enter).
class _NextStepIntent extends Intent {
  const _NextStepIntent();
}

/// Возврат к предыдущему шагу (Alt+←).
class _PreviousStepIntent extends Intent {
  const _PreviousStepIntent();
}

/// Пошаговый мастер заполнения договора (5 шагов).
///
/// Шаги: параметры договора → исполнитель → заказчик → предмет и стоимость →
/// предпросмотр и генерация PDF. Содержит индикатор прогресса, подсказки для
/// каждого поля, валидацию обязательных полей и живой предпросмотр документа.
class ContractWizardScreen extends StatefulWidget {
  final Template template;
  final ContractDraftRepository draftRepository;
  final ContractorProfileRepository profileRepository;

  /// Загрузчик текста шаблона (по умолчанию — из Assets).
  final ContractTemplateTextLoader? templateTextLoader;

  /// Генератор PDF (по умолчанию — встроенная генерация с Roboto).
  final ContractPdfGenerator? pdfGenerator;

  /// Загрузчик шрифтов Roboto для PDF (по умолчанию — из Assets).
  final ContractPdfFontLoader? fontLoader;

  /// Сервис шаринга и сохранения PDF (по умолчанию — системный).
  final ContractPdfShareService? shareService;

  /// Позволяет подменить рендер PDF в листе предпросмотра в тестах.
  final Widget Function()? previewBuilder;

  /// «Сейчас» для предзаполнения даты (для тестов).
  final DateTime? now;

  /// Черновик для редактирования. Если задан — поля заполняются его
  /// значениями, а сохранение обновляет существующую запись.
  final ContractDraft? initialDraft;

  /// Интервал автосохранения черновика (по умолчанию 30 секунд).
  final Duration autosaveInterval;

  const ContractWizardScreen({
    super.key,
    required this.template,
    required this.draftRepository,
    required this.profileRepository,
    this.templateTextLoader,
    this.pdfGenerator,
    this.fontLoader,
    this.shareService,
    this.previewBuilder,
    this.now,
    this.initialDraft,
    this.autosaveInterval = const Duration(seconds: 30),
  });

  @override
  State<ContractWizardScreen> createState() => _ContractWizardScreenState();
}

class _FieldSpec {
  final String key;
  final String label;
  final String helper;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FieldSpec({
    required this.key,
    required this.label,
    required this.helper,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });
}

class _WizardStep {
  final String title;
  final String description;
  final List<_FieldSpec> fields;

  const _WizardStep({
    required this.title,
    required this.description,
    this.fields = const [],
  });
}

class _ContractWizardScreenState extends State<ContractWizardScreen> {
  static const _stepsCount = 5;

  final _formKey = GlobalKey<FormState>();

  late final List<_WizardStep> _steps;
  late final Map<String, TextEditingController> _controllers;
  late final ContractTemplateTextLoader _textLoader;
  late final ContractPdfFontLoader _fontLoader;
  late final ContractPdfShareService _shareService;

  ContractorProfile? _profile;
  String? _templateText;
  Object? _loadError;
  int _step = 0;
  bool _busy = false;

  Timer? _autosaveTimer;
  bool _savingDraft = false;
  int _draftId = 0;
  ContractStatus _initialStatus = ContractStatus.draft;
  DateTime? _lastSavedAt;
  bool _restoredSession = false;

  @override
  void initState() {
    super.initState();
    _textLoader = widget.templateTextLoader ?? const AssetContractTemplateTextLoader();
    _fontLoader = widget.fontLoader ?? const ContractPdfFontLoader();
    _shareService = widget.shareService ?? const ContractPdfShareService();

    final now = widget.now ?? DateTime.now();
    _controllers = {
      for (final key in _allFieldKeys)
        key: TextEditingController(
          text: key == ContractFieldKeys.contractDate
              ? formatContractDate(now)
              : '',
        ),
    };
    _steps = _buildSteps();
    _initialize();
    _loadTemplateText();
    _startAutosave();
  }

  Future<void> _initialize() async {
    await _loadProfile();
    await _restoreDraft();
  }

  void _startAutosave() {
    final interval = widget.autosaveInterval;
    if (interval <= Duration.zero) return;
    _autosaveTimer = Timer.periodic(interval, (_) => _autosave());
  }

  /// Восстанавливает незавершённую сессию: явный [ContractWizardScreen.initialDraft]
  /// или последний черновик этого шаблона.
  Future<void> _restoreDraft() async {
    final initial = widget.initialDraft;
    if (initial != null) {
      _applyDraft(initial);
      return;
    }
    try {
      final drafts = await widget.draftRepository.getByTemplateId(
        widget.template.code,
      );
      for (final draft in drafts) {
        if (draft.status == ContractStatus.draft) {
          _applyDraft(draft);
          _restoredSession = true;
          break;
        }
      }
    } catch (_) {
      // Восстановление не критично: при ошибке начинаем с чистого листа.
    }
    if (_restoredSession && mounted) {
      _showSnack('Восстановлен незавершённый черновик');
    }
  }

  void _applyDraft(ContractDraft draft) {
    _draftId = draft.id;
    _initialStatus = draft.status;
    final fields = contractFieldsToMap(draft.filledFields);
    for (final key in _allFieldKeys) {
      final value = fields[key];
      if (value != null && value.isNotEmpty) {
        _controllers[key]?.text = value;
      }
    }
  }

  Future<void> _autosave() async {
    if (!mounted || _savingDraft || _busy) return;
    _savingDraft = true;
    try {
      await _persistDraft();
      if (!mounted) return;
      setState(() => _lastSavedAt = DateTime.now());
    } catch (_) {
      // Автосохранение не должно мешать пользователю: ошибки молчаливы.
    } finally {
      _savingDraft = false;
    }
  }

  /// Сохраняет (создаёт или обновляет) черновик и возвращает его `id`.
  Future<int> _persistDraft({ContractStatus? status}) async {
    final draft = ContractDraft(
      templateId: widget.template.code,
      filledFields: contractFieldsFromMap(_collectValues()),
      status: status ?? _initialStatus,
    );
    draft.id = _draftId;
    final id = await widget.draftRepository.save(draft);
    _draftId = id;
    return id;
  }

  static const _allFieldKeys = [
    ContractFieldKeys.contractNumber,
    ContractFieldKeys.contractDate,
    ContractFieldKeys.contractCity,
    ContractFieldKeys.executorFullName,
    ContractFieldKeys.executorInn,
    ContractFieldKeys.executorOgrnip,
    ContractFieldKeys.executorAddress,
    ContractFieldKeys.clientName,
    ContractFieldKeys.clientInn,
    ContractFieldKeys.clientAddress,
    ContractFieldKeys.subject,
    ContractFieldKeys.amount,
  ];

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await widget.profileRepository.load();
    if (!mounted) return;
    setState(() => _profile = profile);
    if (profile == null) return;
    _setController(ContractFieldKeys.executorFullName, profile.fullName);
    _setController(ContractFieldKeys.executorInn, profile.inn);
    _setController(ContractFieldKeys.executorOgrnip, profile.ogrnip);
    _setController(
      ContractFieldKeys.executorAddress,
      profile.registrationAddress,
    );
  }

  void _setController(String key, String value) {
    if (value.isEmpty) return;
    _controllers[key]?.text = value;
  }

  Future<void> _loadTemplateText() async {
    try {
      final text = await _textLoader.load(widget.template.code);
      if (!mounted) return;
      setState(() {
        _templateText = text;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  List<_WizardStep> _buildSteps() {
    return [
      _WizardStep(
        title: 'Параметры договора',
        description: 'Номер, дата и место заключения договора.',
        fields: [
          _FieldSpec(
            key: ContractFieldKeys.contractNumber,
            label: 'Номер договора',
            helper: 'Например, 14/09. Оставьте пустым, если нумерация не нужна.',
          ),
          _FieldSpec(
            key: ContractFieldKeys.contractDate,
            label: 'Дата договора',
            helper: 'Дата подписания. По умолчанию — сегодня, формат ДД.ММ.ГГГГ.',
          ),
          _FieldSpec(
            key: ContractFieldKeys.contractCity,
            label: 'Город заключения',
            helper: 'Город, в котором заключается договор, например Москва.',
          ),
        ],
      ),
      _WizardStep(
        title: 'Исполнитель',
        description: 'Ваши реквизиты подставляются из профиля автоматически.',
        fields: [
          _FieldSpec(
            key: ContractFieldKeys.executorFullName,
            label: 'ФИО исполнителя (ИП)',
            helper: 'ФИО как в паспорте, например Иванов Иван Иванович.',
            validator: _required('Укажите ФИО исполнителя'),
          ),
          _FieldSpec(
            key: ContractFieldKeys.executorInn,
            label: 'ИНН исполнителя',
            helper: '12 цифр — ИНН индивидуального предпринимателя.',
            keyboardType: TextInputType.number,
            validator: _innValidator,
          ),
          _FieldSpec(
            key: ContractFieldKeys.executorOgrnip,
            label: 'ОГРНИП',
            helper: '15 цифр из выписки ЕГРИП.',
            keyboardType: TextInputType.number,
            validator: _required('Укажите ОГРНИП'),
          ),
          _FieldSpec(
            key: ContractFieldKeys.executorAddress,
            label: 'Адрес регистрации',
            helper: 'Адрес регистрации ИП, указанный в ЕГРИП.',
            validator: _required('Укажите адрес регистрации'),
          ),
        ],
      ),
      _WizardStep(
        title: 'Заказчик',
        description: 'Данные контрагента, с которым заключается договор.',
        fields: [
          _FieldSpec(
            key: ContractFieldKeys.clientName,
            label: 'Заказчик',
            helper: 'Наименование организации или ФИО ИП-заказчика.',
            validator: _required('Укажите заказчика'),
          ),
          _FieldSpec(
            key: ContractFieldKeys.clientInn,
            label: 'ИНН заказчика',
            helper: '10 цифр — для организации, 12 — для ИП.',
            keyboardType: TextInputType.number,
            validator: _innValidator,
          ),
          _FieldSpec(
            key: ContractFieldKeys.clientAddress,
            label: 'Адрес заказчика',
            helper: 'Юридический адрес заказчика. Поле необязательное.',
          ),
        ],
      ),
      _WizardStep(
        title: 'Предмет и стоимость',
        description: 'Что именно вы выполняете и сколько это стоит.',
        fields: [
          _FieldSpec(
            key: ContractFieldKeys.subject,
            label: 'Предмет договора',
            helper: 'Опишите услуги или работы и результат, который получит заказчик.',
            maxLines: 4,
            validator: _required('Опишите предмет договора'),
          ),
          _FieldSpec(
            key: ContractFieldKeys.amount,
            label: 'Стоимость, ₽',
            helper: 'Сумма вознаграждения в рублях, например 150000.',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _amountValidator,
          ),
        ],
      ),
      _WizardStep(
        title: 'Предпросмотр',
        description: 'Проверьте договор и создайте PDF-файл.',
      ),
    ];
  }

  static String? Function(String?) _required(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) return message;
      return null;
    };
  }

  static String? _innValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Укажите ИНН';
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'ИНН должен содержать только цифры';
    }
    if (trimmed.length != 10 && trimmed.length != 12) {
      return 'ИНН: 10 или 12 цифр';
    }
    return null;
  }

  static String? _amountValidator(String? value) {
    final cleaned = value?.replaceAll(' ', '') ?? '';
    if (cleaned.isEmpty) return 'Укажите стоимость';
    final parsed = double.tryParse(cleaned.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return 'Стоимость должна быть больше нуля';
    }
    return null;
  }

  bool get _canGoNext {
    if (_step >= _stepsCount - 1) return false;
    if (_step < _stepsCount - 1) {
      final fields = _steps[_step].fields;
      if (fields.isNotEmpty) {
        final form = _formKey.currentState;
        if (form == null || !form.validate()) return false;
      }
    }
    return true;
  }

  void _goNext() {
    if (!_canGoNext) {
      _showSnack('Заполните обязательные поля, чтобы продолжить');
      return;
    }
    setState(() => _step++);
  }

  void _goBack() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  void _jumpToStep(int index) {
    if (index >= _step || index < 0 || index >= _stepsCount) return;
    setState(() => _step = index);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, String> _collectValues() {
    final values = <String, String>{};
    for (final key in _allFieldKeys) {
      // Санитайз — защита в глубину: форматтер и валидатор уже ограничивают
      // ввод, но значения профиля и вставка из буфера тоже должны быть
      // безопасны при подстановке в шаблон.
      var text = ContractInput.sanitize(_controllers[key]?.text ?? '').trim();
      if (key == ContractFieldKeys.amount) {
        text = text.replaceAll(' ', '');
      }
      values[key] = text;
    }
    final profile = _profile;
    values[ContractFieldKeys.executorBankName] = ContractInput.sanitize(
      profile?.bankName ?? '',
    );
    values[ContractFieldKeys.executorBankBik] = ContractInput.sanitize(
      profile?.bankBik ?? '',
    );
    values[ContractFieldKeys.executorBankAccount] = ContractInput.sanitize(
      profile?.bankAccount ?? '',
    );
    return values;
  }

  ComposedContract? _composeCurrent() {
    final text = _templateText;
    if (text == null) return null;
    return composeContractDocument(text, _collectValues());
  }

  String _pdfFileName() {
    final number = (_controllers[ContractFieldKeys.contractNumber]?.text ??
            '')
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    final safeNumber = number.isEmpty ? 'untitled' : number;
    return 'contract_$safeNumber.pdf';
  }

  Future<GeneratedContractPdf> _generatePdf(
    ComposedContract document,
    String fileName,
  ) async {
    final generator = widget.pdfGenerator;
    if (generator != null) return generator(document, fileName);
    final fonts = await _fontLoader.load();
    // Генерация выносится в фоновый изолят, чтобы не блокировать UI.
    return const ContractPdfService().generateInBackground(
      document: document,
      fonts: fonts,
      fileName: fileName,
    );
  }

  Future<void> _createContract() async {
    if (_busy) return;
    if (_templateText == null) {
      _showSnack('Шаблон договора ещё не загружен. Попробуйте ещё раз.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? true)) {
      _showSnack('Заполните обязательные поля');
      return;
    }
    setState(() => _busy = true);
    final document = composeContractDocument(_templateText!, _collectValues());
    final fileName = _pdfFileName();
    try {
      await _persistDraft();
      final pdf = await _generatePdf(document, fileName);
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
      _handleCreateError('Не удалось сохранить черновик. Попробуйте ещё раз.');
    }
  }

  void _handleCreateError(String message) {
    if (!mounted) return;
    setState(() => _busy = false);
    _showSnack(message);
  }

  void _openLivePreview() {
    final document = _composeCurrent();
    if (document == null) return;
    final controllerListenable = Listenable.merge(_controllers.values);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Предпросмотр договора',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Обновляется автоматически по мере заполнения полей.',
                  style: Theme.of(sheetContext).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListenableBuilder(
                  listenable: controllerListenable,
                  builder: (context, _) {
                    final current = _composeCurrent();
                    if (current == null) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ContractDocumentPreview(document: current),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleNextShortcut() {
    if (_step == _stepsCount - 1) {
      _createContract();
    } else {
      _goNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter, control: true):
            _NextStepIntent(),
        SingleActivator(LogicalKeyboardKey.enter, meta: true):
            _NextStepIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
            _PreviousStepIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NextStepIntent: CallbackAction<_NextStepIntent>(
            onInvoke: (_) {
              _handleNextShortcut();
              return null;
            },
          ),
          _PreviousStepIntent: CallbackAction<_PreviousStepIntent>(
            onInvoke: (_) {
              _goBack();
              return null;
            },
          ),
        },
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: _buildScaffold(theme),
        ),
      ),
    );
  }

  Widget _buildScaffold(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialDraft == null
              ? 'Новый договор'
              : 'Редактирование договора',
        ),
        actions: [
          if (_lastSavedAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Tooltip(
                message: 'Черновик сохранён',
                child: Icon(
                  Icons.cloud_done_outlined,
                  key: const Key('autosave_indicator'),
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          IconButton(
            key: const Key('wizard_live_preview_button'),
            tooltip: 'Предпросмотр документа',
            onPressed: _templateText == null ? null : _openLivePreview,
            icon: const Icon(Icons.visibility_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StepProgressHeader(
              step: _step,
              totalSteps: _stepsCount,
              stepTitle: _steps[_step].title,
              onStepTap: _jumpToStep,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _TemplateHeader(template: widget.template),
            ),
            Expanded(
              child: _loadError != null
                  ? _buildLoadError()
                  : _templateText == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildStepContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось загрузить шаблон договора'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() => _loadError = null);
                _loadTemplateText();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    final step = _steps[_step];
    final isLast = _step == _stepsCount - 1;

    if (isLast) {
      return _buildPreviewStep(theme);
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(step.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(step.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          for (final field in step.fields) ...[
            _buildField(field),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          _buildNavigationRow(theme),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(ThemeData theme) {
    final document = _composeCurrent();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text('Предпросмотр документа', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Договор собран из заполненных полей. Нажмите «Создать PDF», '
          'чтобы получить готовый файл.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (document != null)
          ContractDocumentPreview(document: document)
        else
          const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('wizard_create_pdf_button'),
          onPressed: _busy ? null : _createContract,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf_outlined),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_busy ? 'Создание PDF…' : 'Создать PDF'),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: OutlinedButton(
            key: const Key('wizard_back_button'),
            onPressed: _busy ? null : _goBack,
            child: const Text('Назад'),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationRow(ThemeData theme) {
    return Row(
      children: [
        if (_step > 0) ...[
          OutlinedButton(
            key: const Key('wizard_back_button'),
            onPressed: _goBack,
            child: const Text('Назад'),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: FilledButton(
            key: const Key('wizard_next_button'),
            onPressed: _goNext,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _step == _stepsCount - 2 ? 'К предпросмотру' : 'Далее',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(_FieldSpec field) {
    final controller = _controllers[field.key]!;
    final fields = _steps[_step].fields;
    final isFirst = fields.first.key == field.key;
    final isLast = fields.last.key == field.key;
    final isMultiline = field.maxLines > 1;
    return TextFormField(
      key: Key('field_${field.key}'),
      controller: controller,
      validator: (value) {
        final security = ContractInput.validate(value);
        if (security != null) return security;
        return field.validator?.call(value);
      },
      keyboardType: field.keyboardType,
      maxLines: field.maxLines,
      autofocus: isFirst,
      inputFormatters: const [ContractInputFormatter()],
      textInputAction: isMultiline
          ? TextInputAction.newline
          : isLast
          ? TextInputAction.done
          : TextInputAction.next,
      onFieldSubmitted: isMultiline || !isLast
          ? null
          : (_) => _goNext(),
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.helper,
        helperMaxLines: 3,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// Индикатор прогресса мастера: полоса прогресса и шаги с заголовками.
class _StepProgressHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String stepTitle;
  final void Function(int index) onStepTap;

  const _StepProgressHeader({
    required this.step,
    required this.totalSteps,
    required this.stepTitle,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalSteps <= 1 ? 1.0 : step / (totalSteps - 1);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Шаг ${step + 1} из $totalSteps',
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Шаг ${step + 1} из $totalSteps',
                  style: theme.textTheme.labelMedium!.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stepTitle,
                    style: theme.textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                key: const Key('wizard_progress'),
                value: progress,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < totalSteps; i++) ...[
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i <= step
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                    ),
                  _StepDot(
                    index: i,
                    active: i == step,
                    reached: i < step,
                    onTap: i < step ? () => onStepTap(i) : null,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final bool active;
  final bool reached;
  final VoidCallback? onTap;

  const _StepDot({
    required this.index,
    required this.active,
    required this.reached,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = active
        ? colorScheme.primary
        : reached
        ? colorScheme.primary.withValues(alpha: 0.4)
        : colorScheme.outlineVariant;

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: 'Перейти к шагу ${index + 1}',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached || active ? color : colorScheme.surface,
            border: active || !reached
                ? Border.all(color: color, width: 2)
                : null,
          ),
          child: Center(
            child: reached
                ? Icon(Icons.check, size: 16, color: colorScheme.surface)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? colorScheme.surface : color,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Карточка выбранного шаблона вверху мастера.
class _TemplateHeader extends StatelessWidget {
  final Template template;

  const _TemplateHeader({required this.template});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: template.sphere.color.withValues(alpha: 0.1),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(template.sphere.icon, color: template.sphere.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    template.sphere.category,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: template.sphere.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
