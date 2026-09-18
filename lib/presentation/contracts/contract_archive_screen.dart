import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/contract_draft.dart';
import '../../data/models/contract_template.dart';
import '../../data/models/transaction.dart';
import '../../data/pdf/act_pdf_service.dart';
import '../../data/pdf/contract_pdf_font_loader.dart';
import '../../data/pdf/contract_pdf_share_service.dart';
import '../../data/pdf/receipt_pdf_service.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/contract_draft_repository.dart';
import '../../data/repositories/contract_template_repository.dart';
import '../../data/repositories/contractor_profile_repository.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/repositories/risk_report_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/contracts/contract_search.dart';
import '../../domain/contracts/contract_status.dart';
import '../../domain/risk/risk_analyzer.dart';
import '../documents/act_screen.dart';
import '../documents/deal_completion_screen.dart';
import 'contract_status_visuals.dart';
import 'contract_wizard_screen.dart';

/// Экран «Мои договоры»: список сохранённых договоров с управлением.
///
/// Позволяет искать договоры по названию, контрагенту и дате, фильтровать
/// по статусу, редактировать черновики, дублировать и переводить договоры
/// между статусами Черновик → Подписан → Архив.
class ContractArchiveScreen extends StatefulWidget {
  final ContractDraftRepository draftRepository;
  final ContractTemplateRepository templateRepository;
  final ContractorProfileRepository profileRepository;

  /// Анализатор рисков Risk Shield для автопроверки при редактировании.
  final RiskAnalyzerUseCase? riskAnalyzer;

  /// Репозиторий истории проверок Risk Shield.
  final RiskReportRepository? riskReportRepository;

  /// Репозиторий архива документов. Если задан — доступно завершение сделки
  /// с автоформированием чека.
  final DocumentRepository? documentRepository;

  /// Репозиторий транзакций для записи дохода при завершении сделки.
  final TransactionRepository? transactionRepository;

  /// Справочник клиентов. Если задан — заказчика можно выбрать из него.
  final ClientRepository? clientRepository;

  /// Необязательные зависимости экрана завершения сделки (для тестов).
  final ReceiptPdfGenerator? receiptPdfGenerator;
  final ContractPdfFontLoader? fontLoader;
  final ContractPdfShareService? shareService;
  final Widget Function()? previewBuilder;

  /// Необязательный генератор PDF акта (для тестов).
  final ActPdfGenerator? actPdfGenerator;

  /// Открывает боковое меню навигации. Если задан, в шапке появляется
  /// кнопка-гамбургер (используется на телефоне).
  final VoidCallback? onOpenMenu;

  const ContractArchiveScreen({
    super.key,
    required this.draftRepository,
    required this.templateRepository,
    required this.profileRepository,
    this.riskAnalyzer,
    this.riskReportRepository,
    this.documentRepository,
    this.transactionRepository,
    this.clientRepository,
    this.receiptPdfGenerator,
    this.fontLoader,
    this.shareService,
    this.previewBuilder,
    this.actPdfGenerator,
    this.onOpenMenu,
  });

  @override
  State<ContractArchiveScreen> createState() => _ContractArchiveScreenState();
}

class _ContractArchiveScreenState extends State<ContractArchiveScreen> {
  static const int _pageSize = ContractDraftRepository.defaultPageSize;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  /// Номер последней запущенной загрузки: защищает от устаревших ответов,
  /// если пользователь быстро меняет запрос или фильтр.
  int _loadGeneration = 0;

  Map<String, Template> _templates = {};
  List<ContractDraft> _drafts = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;
  String _query = '';
  ContractStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_loading || _loadingMore || !_hasMore) return;
    if (_query.trim().isNotEmpty) return;
    _load(reset: false);
  }

  Future<void> _load({bool reset = true, bool silent = false}) async {
    final generation = ++_loadGeneration;
    if (reset) {
      if (!silent) {
        setState(() {
          _loading = true;
          _error = null;
          _drafts = [];
          _hasMore = true;
        });
      }
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final templates = await widget.templateRepository.getAll();
      final List<ContractDraft> drafts;
      final bool hasMore;
      if (_query.trim().isNotEmpty) {
        // Поиск — намеренное действие пользователя: ищем по всем договорам,
        // а не только по загруженной странице.
        drafts = _statusFilter == null
            ? await widget.draftRepository.getAll()
            : await widget.draftRepository.getByStatus(_statusFilter!);
        hasMore = false;
      } else {
        final page = await widget.draftRepository.getPage(
          offset: reset ? 0 : _drafts.length,
          limit: _pageSize,
          status: _statusFilter,
        );
        drafts = page;
        hasMore = page.length == _pageSize;
      }
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _templates = {for (final t in templates) t.code: t};
        _drafts = reset ? drafts : [..._drafts, ...drafts];
        _hasMore = hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = error;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    // Тихая перезагрузка: список не мигает, пока ищем по всем договорам.
    _load(silent: true);
  }

  void _selectStatus(ContractStatus? status) {
    setState(() => _statusFilter = status);
    _load();
  }

  String _titleOf(ContractDraft draft) =>
      _templates[draft.templateId]?.title ?? 'Шаблон недоступен';

  String _clientOf(ContractDraft draft) =>
      contractFieldsToMap(draft.filledFields)[ContractFieldKeys.clientName] ??
      '';

  List<ContractDraft> get _visibleDrafts {
    final byStatus = _statusFilter == null
        ? _drafts
        : _drafts.where((d) => d.status == _statusFilter).toList();
    return filterContractsByQuery(
      drafts: byStatus,
      titleOf: _titleOf,
      query: _query,
    );
  }

  Future<void> _openWizard(ContractDraft draft) async {
    final template = _templates[draft.templateId];
    if (template == null) {
      _showSnack('Шаблон договора не найден');
      return;
    }
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ContractWizardScreen(
          template: template,
          draftRepository: widget.draftRepository,
          profileRepository: widget.profileRepository,
          initialDraft: draft,
          riskAnalyzer: widget.riskAnalyzer,
          riskReportRepository: widget.riskReportRepository,
          documentRepository: widget.documentRepository,
          clientRepository: widget.clientRepository,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openDealCompletion(ContractDraft draft) async {
    final documentRepository = widget.documentRepository;
    if (documentRepository == null) {
      _showSnack('Архив документов недоступен');
      return;
    }
    final template = _templates[draft.templateId];
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DealCompletionScreen(
          draft: draft,
          templateTitle: _titleOf(draft),
          profileRepository: widget.profileRepository,
          documentRepository: documentRepository,
          transactionRepository: widget.transactionRepository,
          clientRepository: widget.clientRepository,
          sphere: _sphereOf(template),
          pdfGenerator: widget.receiptPdfGenerator,
          fontLoader: widget.fontLoader,
          shareService: widget.shareService,
          previewBuilder: widget.previewBuilder,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openAct(ContractDraft draft) async {
    final documentRepository = widget.documentRepository;
    if (documentRepository == null) {
      _showSnack('Архив документов недоступен');
      return;
    }
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ActScreen(
          draft: draft,
          templateTitle: _titleOf(draft),
          profileRepository: widget.profileRepository,
          documentRepository: documentRepository,
          pdfGenerator: widget.actPdfGenerator,
          fontLoader: widget.fontLoader,
          shareService: widget.shareService,
          previewBuilder: widget.previewBuilder,
        ),
      ),
    );
    if (mounted) await _load();
  }

  /// Сопоставляет сферу шаблона со сферой транзакции дашборда.
  static TransactionSphere? _sphereOf(Template? template) {
    return switch (template?.sphere) {
      TemplateSphere.it => TransactionSphere.it,
      TemplateSphere.logistics => TransactionSphere.logistics,
      TemplateSphere.universal => TransactionSphere.it,
      null => null,
    };
  }

  Future<void> _duplicate(ContractDraft draft) async {
    final copy = ContractDraft(
      templateId: draft.templateId,
      filledFields: contractFieldsFromMap(
        contractFieldsToMap(draft.filledFields),
      ),
      status: ContractStatus.draft,
    );
    copy.createdAt = DateTime.now();
    await widget.draftRepository.save(copy);
    if (!mounted) return;
    _showSnack('Договор продублирован');
    await _load();
  }

  Future<void> _changeStatus(
    ContractDraft draft,
    ContractStatus target,
  ) async {
    final next = draft.status.transitionTo(target);
    if (next == null) {
      _showSnack('Недопустимый переход статуса');
      return;
    }
    final updated = ContractDraft(
      templateId: draft.templateId,
      filledFields: contractFieldsFromMap(
        contractFieldsToMap(draft.filledFields),
      ),
      status: next,
    );
    updated.id = draft.id;
    updated.createdAt = draft.createdAt;
    await widget.draftRepository.save(updated);
    if (!mounted) return;
    _showSnack('Статус изменён: ${next.label}');
    await _load();
  }

  Future<void> _delete(ContractDraft draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить договор?'),
        content: const Text('Действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            key: const Key('confirm_delete_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.draftRepository.delete(draft.id);
    if (!mounted) return;
    _showSnack('Договор удалён');
    await _load();
  }

  void _onAction(ContractDraft draft, String action) {
    if (action == 'edit') {
      _openWizard(draft);
    } else if (action == 'complete') {
      _openDealCompletion(draft);
    } else if (action == 'act') {
      _openAct(draft);
    } else if (action == 'duplicate') {
      _duplicate(draft);
    } else if (action == 'delete') {
      _delete(draft);
    } else if (action.startsWith('status:')) {
      final name = action.substring('status:'.length);
      final target = ContractStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => draft.status,
      );
      _changeStatus(draft, target);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои договоры'),
        leading: widget.onOpenMenu == null
            ? null
            : AppMenuButton(
                key: const Key('contract_archive_menu_button'),
                onPressed: widget.onOpenMenu!,
              ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: AppTextField(
              key: const Key('contract_search_field'),
              controller: _searchController,
              hint: 'Поиск по названию, контрагенту, дате',
              dense: true,
              prefixIcon: const Icon(Icons.search),
              onChanged: _onQueryChanged,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('contract_search_clear'),
                      tooltip: 'Очистить поиск',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                        _load();
                      },
                    ),
            ),
          ),
          _buildStatusFilters(),
          const SizedBox(height: AppSpacing.xxs),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          AppFilterChip(
            key: const Key('status_filter_all'),
            label: 'Все',
            selected: _statusFilter == null,
            onSelected: () => _selectStatus(null),
          ),
          for (final status in ContractStatus.values)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: AppFilterChip(
                key: Key('status_filter_${status.name}'),
                label: status.label,
                icon: status.icon,
                selected: _statusFilter == status,
                onSelected: () => _selectStatus(status),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingState(semanticLabel: 'Загрузка договоров');
    }
    if (_error != null) {
      return AppErrorState(
        message: 'Не удалось загрузить договоры',
        retryKey: const Key('contract_archive_retry'),
        onRetry: _load,
      );
    }
    final drafts = _visibleDrafts;
    if (drafts.isEmpty) {
      final isEmpty = _drafts.isEmpty;
      return AppEmptyState(
        key: const Key('contract_archive_empty'),
        icon: isEmpty ? Icons.description_outlined : Icons.search_off,
        title: isEmpty ? 'Договоров пока нет' : 'Ничего не найдено',
        message: isEmpty
            ? 'Создайте договор из библиотеки шаблонов.'
            : 'Измените запрос или статус.',
      );
    }
    final showFooter = _hasMore || _loadingMore;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        key: const Key('contract_archive_list'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        itemCount: drafts.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= drafts.length) {
            return const Padding(
              key: Key('contract_archive_loading_more'),
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final draft = drafts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ContractCard(
              key: Key('contract_card_${draft.id}'),
              draftId: draft.id,
              title: _titleOf(draft),
              client: _clientOf(draft),
              number:
                  contractFieldsToMap(draft.filledFields)[
                      ContractFieldKeys.contractNumber] ??
                  '',
              date:
                  contractFieldsToMap(draft.filledFields)[
                      ContractFieldKeys.contractDate] ??
                  '',
              status: draft.status,
              canComplete:
                  widget.documentRepository != null &&
                  draft.status == ContractStatus.signed,
              canCreateAct:
                  widget.documentRepository != null &&
                  draft.status == ContractStatus.signed,
              onTap: () => _openWizard(draft),
              onAction: (action) => _onAction(draft, action),
            ),
          );
        },
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final int draftId;
  final String title;
  final String client;
  final String number;
  final String date;
  final ContractStatus status;
  final bool canComplete;
  final bool canCreateAct;
  final VoidCallback onTap;
  final void Function(String action) onAction;

  const _ContractCard({
    super.key,
    required this.draftId,
    required this.title,
    required this.client,
    required this.number,
    required this.date,
    required this.status,
    required this.canComplete,
    required this.canCreateAct,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final subtitleParts = [
      if (client.isNotEmpty) client,
      if (number.isNotEmpty) '№ $number',
      if (date.isNotEmpty) date,
    ];

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xxs,
        AppSpacing.sm,
      ),
      onTap: onTap,
      semanticLabel:
          '$title${subtitleParts.isEmpty ? '' : '. ${subtitleParts.join(', ')}'}. '
          'Статус: ${status.label}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitleParts.join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.muted,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                AppStatusChip(
                  label: status.label,
                  color: status.color(tokens),
                  icon: status.icon,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            key: Key('contract_menu_$draftId'),
            tooltip: 'Действия с договором',
            onSelected: onAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Редактировать'),
              ),
              if (canComplete)
                const PopupMenuItem(
                  value: 'complete',
                  child: Text('Завершить сделку'),
                ),
              if (canCreateAct)
                const PopupMenuItem(
                  value: 'act',
                  child: Text('Создать акт'),
                ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Text('Дублировать'),
              ),
              for (final target in status.allowedTransitions)
                PopupMenuItem(
                  value: 'status:${target.name}',
                  child: Text(_statusActionLabel(status, target)),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Удалить'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _statusActionLabel(
    ContractStatus from,
    ContractStatus to,
  ) {
    if (to == ContractStatus.signed && from == ContractStatus.archived) {
      return 'Вернуть из архива';
    }
    if (to == ContractStatus.signed) return 'Отметить подписанным';
    if (to == ContractStatus.draft) return 'Вернуть в черновик';
    return 'В архив';
  }
}
