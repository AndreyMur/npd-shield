import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/document.dart';
import '../../data/pdf/contract_pdf_font_loader.dart';
import '../../data/pdf/contract_pdf_share_service.dart';
import '../../data/pdf/document_pdf_service.dart';
import '../../data/pdf/generated_pdf.dart';
import '../../data/repositories/document_repository.dart';
import '../../domain/documents/document_archive.dart';
import '../../domain/documents/legal_disclaimer.dart';
import 'document_card.dart';
import 'document_details_sheet.dart';

/// Экран единого архива документов: чеки, акты и договоры.
///
/// Документы группируются по контрагентам, сортируются по дате, сумме или
/// типу, фильтруются по типу и статусу, ищутся по контрагенту, сумме и дате
/// с автодополнением. По нажатию на карточку открывается Bottom sheet с
/// деталями и действиями «Отправить», «Скачать PDF», «Удалить».
class DocumentArchiveScreen extends StatefulWidget {
  final DocumentRepository documentRepository;

  /// Генератор PDF-версии документа (для тестов). По умолчанию — встроенный.
  final DocumentPdfGenerator? pdfGenerator;

  /// Загрузчик шрифтов Roboto для PDF (по умолчанию — из Assets).
  final ContractPdfFontLoader? fontLoader;

  /// Сервис шаринга и сохранения PDF (по умолчанию — системный).
  final ContractPdfShareService? shareService;

  /// Открывает боковое меню навигации. Если задан, в шапке появляется
  /// кнопка-гамбургер (используется на телефоне).
  final VoidCallback? onOpenMenu;

  const DocumentArchiveScreen({
    super.key,
    required this.documentRepository,
    this.pdfGenerator,
    this.fontLoader,
    this.shareService,
    this.onOpenMenu,
  });

  @override
  State<DocumentArchiveScreen> createState() => _DocumentArchiveScreenState();
}

class _DocumentArchiveScreenState extends State<DocumentArchiveScreen> {
  static const _sortOptions = <DocumentSort>[
    DocumentSort(
      field: DocumentSortField.date,
      direction: SortDirection.descending,
    ),
    DocumentSort(
      field: DocumentSortField.date,
      direction: SortDirection.ascending,
    ),
    DocumentSort(
      field: DocumentSortField.amount,
      direction: SortDirection.descending,
    ),
    DocumentSort(
      field: DocumentSortField.amount,
      direction: SortDirection.ascending,
    ),
    DocumentSort(
      field: DocumentSortField.type,
      direction: SortDirection.ascending,
    ),
  ];

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  late final ContractPdfShareService _shareService;
  late final DocumentPdfService _pdfService;

  List<Document> _documents = [];
  DocumentArchiveFilter _filter = const DocumentArchiveFilter();
  DocumentSort _sort = const DocumentSort();
  bool _grouped = true;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _shareService = widget.shareService ?? const ContractPdfShareService();
    _pdfService = DocumentPdfService(
      fontLoader: widget.fontLoader ?? const ContractPdfFontLoader(),
    );
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final documents = await widget.documentRepository.getAll();
      if (!mounted) return;
      setState(() {
        _documents = documents;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  List<Document> get _visible => applyDocumentArchive(
    documents: _documents,
    filter: _filter,
    sort: _sort,
  );

  List<_ArchiveEntry> get _entries {
    final visible = _visible;
    if (!_grouped) {
      return [for (final document in visible) _ArchiveEntry.document(document)];
    }
    final entries = <_ArchiveEntry>[];
    for (final group in groupDocumentsByCounterparty(visible)) {
      entries.add(
        _ArchiveEntry.header(group.counterpartyName, group.documents.length),
      );
      for (final document in group.documents) {
        entries.add(_ArchiveEntry.document(document));
      }
    }
    return entries;
  }

  void _setQuery(String value) {
    setState(() => _filter = _filter.copyWith(query: value));
  }

  void _selectType(DocumentType? type) {
    setState(() {
      _filter = type == null
          ? _filter.copyWith(clearType: true)
          : _filter.copyWith(type: type);
    });
  }

  void _selectStatus(DocumentStatus? status) {
    setState(() {
      _filter = status == null
          ? _filter.copyWith(clearStatus: true)
          : _filter.copyWith(status: status);
    });
  }

  Future<void> _openDetails(Document document) async {
    final deleted = await showDocumentDetailsSheet(
      context,
      document: document,
      pdfGenerator: _generatePdf,
      shareService: _shareService,
      onDelete: () => widget.documentRepository.delete(document.id),
    );
    if (deleted && mounted) await _load(silent: true);
  }

  Future<GeneratedPdf> _generatePdf(Document document) {
    final generator = widget.pdfGenerator;
    if (generator != null) return generator(document);
    return _pdfService.generate(document);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Архив документов'),
        leading: widget.onOpenMenu == null
            ? null
            : AppMenuButton(
                key: const Key('document_archive_menu_button'),
                onPressed: widget.onOpenMenu!,
              ),
        actions: [
          IconButton(
            key: const Key('document_group_toggle'),
            tooltip: _grouped
                ? 'Отключить группировку по контрагентам'
                : 'Группировать по контрагентам',
            isSelected: _grouped,
            icon: const Icon(Icons.workspaces_outline),
            selectedIcon: const Icon(Icons.workspaces),
            onPressed: () => setState(() => _grouped = !_grouped),
          ),
          PopupMenuButton<DocumentSort>(
            key: const Key('document_sort_button'),
            tooltip: 'Сортировка',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (context) => [
              for (final option in _sortOptions)
                PopupMenuItem<DocumentSort>(
                  key: Key(
                    'document_sort_${option.field.name}_'
                    '${option.direction.name}',
                  ),
                  value: option,
                  child: Text(_sortOptionLabel(option)),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const _DisclaimerBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: _buildSearchField(),
          ),
          _buildTypeFilters(),
          _buildStatusFilters(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                Icon(Icons.sort, size: 16, color: AppTokens.of(context).muted),
                const SizedBox(width: 6),
                Text(
                  _sort.label,
                  key: const Key('document_sort_label'),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return RawAutocomplete<String>(
      textEditingController: _searchController,
      focusNode: _searchFocus,
      optionsBuilder: (value) => documentSearchSuggestions(
        documents: _documents,
        query: value.text,
      ),
      onSelected: (value) {
        _searchController.text = value;
        _setQuery(value);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return AppTextField(
          key: const Key('document_search_field'),
          controller: controller,
          focusNode: focusNode,
          onChanged: _setQuery,
          onSubmitted: (_) => onFieldSubmitted(),
          hint: 'Поиск по контрагенту, сумме, дате',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  key: const Key('document_search_clear'),
                  tooltip: 'Очистить поиск',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    _setQuery('');
                  },
                ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 420),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    key: Key('document_suggestion_$index'),
                    dense: true,
                    leading: const Icon(Icons.search),
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeFilters() {
    final tokens = AppTokens.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          AppFilterChip(
            key: const Key('document_type_filter_all'),
            label: 'Все',
            selected: _filter.type == null,
            onSelected: () => _selectType(null),
          ),
          for (final type in DocumentType.values)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: AppFilterChip(
                key: Key('document_type_filter_${type.name}'),
                label: type.label,
                selected: _filter.type == type,
                accent: type == DocumentType.contract
                    ? tokens.sphereIt
                    : type == DocumentType.act
                        ? tokens.warning
                        : tokens.success,
                icon: type == DocumentType.contract
                    ? Icons.description_outlined
                    : type == DocumentType.act
                        ? Icons.assignment_turned_in_outlined
                        : Icons.receipt_long_outlined,
                onSelected: () => _selectType(type),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          AppFilterChip(
            key: const Key('document_status_filter_all'),
            label: 'Все статусы',
            selected: _filter.status == null,
            onSelected: () => _selectStatus(null),
          ),
          for (final status in DocumentStatus.values)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: AppFilterChip(
                key: Key('document_status_filter_${status.name}'),
                label: status.label,
                selected: _filter.status == status,
                onSelected: () => _selectStatus(status),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingState(semanticLabel: 'Загрузка документов');
    }
    if (_error != null) {
      return AppErrorState(
        message: 'Не удалось загрузить документы',
        retryKey: const Key('document_archive_retry'),
        onRetry: _load,
      );
    }
    final entries = _entries;
    if (entries.isEmpty) {
      final isEmpty = _documents.isEmpty;
      return AppEmptyState(
        key: const Key('document_archive_empty'),
        icon: isEmpty ? Icons.folder_open_outlined : Icons.search_off,
        title: isEmpty ? 'Документов пока нет' : 'Ничего не найдено',
        message: isEmpty
            ? 'Создайте чек, акт или договор — они появятся здесь.'
            : null,
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView.builder(
        key: const Key('document_archive_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          if (entry.isHeader) return _buildGroupHeader(entry);
          final document = entry.document!;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: KeyedSubtree(
              key: Key('document_entry_${document.id}'),
              child: DocumentCard(
                document: document,
                onTap: () => _openDetails(document),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupHeader(_ArchiveEntry entry) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final title = entry.header!;
    return Padding(
      key: Key('document_group_$title'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxs,
        AppSpacing.md,
        AppSpacing.xxs,
        AppSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: tokens.primary.withValues(alpha: 0.12),
              child: Text(
                title.substring(0, 1).toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tokens.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(title, style: theme.textTheme.titleSmall),
            ),
            Text(
              '${entry.headerCount}',
              style: theme.textTheme.labelSmall?.copyWith(color: tokens.muted),
            ),
          ],
        ),
      ),
    );
  }

  static String _sortOptionLabel(DocumentSort sort) {
    return switch (sort.field) {
      DocumentSortField.date => sort.direction == SortDirection.descending
          ? 'Сначала новые'
          : 'Сначала старые',
      DocumentSortField.amount => sort.direction == SortDirection.descending
          ? 'Сумма: по убыванию'
          : 'Сумма: по возрастанию',
      DocumentSortField.type => 'По типу документа',
    };
  }
}

/// Элемент плоского списка архива: заголовок группы или документ.
class _ArchiveEntry {
  final String? header;
  final int headerCount;
  final Document? document;

  const _ArchiveEntry.header(this.header, this.headerCount) : document = null;

  const _ArchiveEntry.document(this.document)
    : header = null,
      headerCount = 0;

  bool get isHeader => document == null;
}

/// Баннер-дисклеймер об отсутствии юридической силы документов без ЭЦП.
class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: Key('document_archive_disclaimer'),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      child: StatusBanner(
        type: StatusBannerType.info,
        message: kNoLegalForceDisclaimer,
      ),
    );
  }
}
