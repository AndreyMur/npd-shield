import 'package:flutter/material.dart';

import '../../core/constants/tax_constants.dart';
import '../../core/tax/tax_calculator.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/transaction.dart';
import '../../data/pdf/contract_pdf_font_loader.dart';
import '../../data/pdf/contract_pdf_share_service.dart';
import '../../data/pdf/document_pdf_service.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/limit/limit_calculator.dart';
import 'income_chart_card.dart';
import 'transaction_documents_card.dart';

enum DashboardFilter { all, it, logistics }

class DashboardScreen extends StatefulWidget {
  final TransactionRepository repository;
  final DateTime? now;

  /// Репозиторий архива документов. Если задан — под сводкой показывается
  /// список транзакций со значками привязанных документов.
  final DocumentRepository? documentRepository;

  /// Открывает форму создания операции. Если задан, пустое состояние
  /// показывает кнопку «Добавить операцию».
  final VoidCallback? onAddOperation;

  /// Необязательные зависимости карточки документов (для тестов).
  final DocumentPdfGenerator? pdfGenerator;
  final ContractPdfShareService? shareService;
  final ContractPdfFontLoader? fontLoader;

  const DashboardScreen({
    super.key,
    required this.repository,
    this.now,
    this.documentRepository,
    this.onAddOperation,
    this.pdfGenerator,
    this.shareService,
    this.fontLoader,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardFilter _filter = DashboardFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дашборд'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: SegmentedButton<DashboardFilter>(
              segments: const [
                ButtonSegment(
                  value: DashboardFilter.all,
                  label: Text('Все'),
                  icon: Icon(Icons.all_inclusive),
                ),
                ButtonSegment(
                  value: DashboardFilter.it,
                  label: Text('IT'),
                  icon: Icon(Icons.code),
                ),
                ButtonSegment(
                  value: DashboardFilter.logistics,
                  label: Text('Логистика'),
                  icon: Icon(Icons.local_shipping),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) {
                setState(() => _filter = selection.first);
              },
            ),
          ),
          Expanded(
            child: _DashboardView(
              future: _load(_filter),
              filter: _filter,
              repository: widget.repository,
              documentRepository: widget.documentRepository,
              onAddOperation: widget.onAddOperation,
              pdfGenerator: widget.pdfGenerator,
              shareService: widget.shareService,
              fontLoader: widget.fontLoader,
              now: widget.now ?? DateTime.now(),
            ),
          ),
        ],
      ),
    );
  }

  Future<_DashboardData> _load(DashboardFilter filter) async {
    final now = widget.now ?? DateTime.now();
    final transactionCount = await widget.repository.count();
    switch (filter) {
      case DashboardFilter.all:
        final values = await Future.wait([
          widget.repository.getIncomeSummary(now: now),
          widget.repository
              .getIncomeSummary(sphere: TransactionSphere.it, now: now),
          widget.repository
              .getIncomeSummary(sphere: TransactionSphere.logistics, now: now),
          widget.repository.getAverageMonthlyIncome(now: now),
        ]);
        return _DashboardData(
          total: values[0] as IncomeSummary,
          it: values[1] as IncomeSummary,
          logistics: values[2] as IncomeSummary,
          averageMonthlyIncome: values[3] as double,
          transactionCount: transactionCount,
        );
      case DashboardFilter.it:
        final values = await Future.wait([
          widget.repository
              .getIncomeSummary(sphere: TransactionSphere.it, now: now),
          widget.repository.getAverageMonthlyIncome(
            sphere: TransactionSphere.it,
            now: now,
          ),
        ]);
        return _DashboardData(
          total: values[0] as IncomeSummary,
          averageMonthlyIncome: values[1] as double,
          transactionCount: transactionCount,
        );
      case DashboardFilter.logistics:
        final values = await Future.wait([
          widget.repository
              .getIncomeSummary(sphere: TransactionSphere.logistics, now: now),
          widget.repository.getAverageMonthlyIncome(
            sphere: TransactionSphere.logistics,
            now: now,
          ),
        ]);
        return _DashboardData(
          total: values[0] as IncomeSummary,
          averageMonthlyIncome: values[1] as double,
          transactionCount: transactionCount,
        );
    }
  }
}

class _DashboardData {
  final IncomeSummary? total;
  final IncomeSummary? it;
  final IncomeSummary? logistics;
  final double averageMonthlyIncome;
  final int transactionCount;

  const _DashboardData({
    this.total,
    this.it,
    this.logistics,
    this.averageMonthlyIncome = 0,
    this.transactionCount = 0,
  });
}

class _DashboardView extends StatelessWidget {
  final Future<_DashboardData> future;
  final DashboardFilter filter;
  final TransactionRepository repository;
  final DocumentRepository? documentRepository;
  final VoidCallback? onAddOperation;
  final DocumentPdfGenerator? pdfGenerator;
  final ContractPdfShareService? shareService;
  final ContractPdfFontLoader? fontLoader;
  final DateTime now;

  const _DashboardView({
    required this.future,
    required this.filter,
    required this.repository,
    required this.now,
    this.documentRepository,
    this.onAddOperation,
    this.pdfGenerator,
    this.shareService,
    this.fontLoader,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('Не удалось загрузить данные'));
        }
        return _DashboardBody(
          data: snapshot.data!,
          filter: filter,
          repository: repository,
          documentRepository: documentRepository,
          onAddOperation: onAddOperation,
          pdfGenerator: pdfGenerator,
          shareService: shareService,
          fontLoader: fontLoader,
          now: now,
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final _DashboardData data;
  final DashboardFilter filter;
  final TransactionRepository repository;
  final DocumentRepository? documentRepository;
  final VoidCallback? onAddOperation;
  final DocumentPdfGenerator? pdfGenerator;
  final ContractPdfShareService? shareService;
  final ContractPdfFontLoader? fontLoader;
  final DateTime now;

  const _DashboardBody({
    required this.data,
    required this.filter,
    required this.repository,
    required this.now,
    this.documentRepository,
    this.onAddOperation,
    this.pdfGenerator,
    this.shareService,
    this.fontLoader,
  });

  @override
  Widget build(BuildContext context) {
    if (data.transactionCount == 0) {
      return ListView(
        padding: AppSpacing.screen,
        children: [_EmptyState(onAddOperation: onAddOperation)],
      );
    }

    final title = switch (filter) {
      DashboardFilter.all => 'Все сферы',
      DashboardFilter.it => 'IT',
      DashboardFilter.logistics => 'Логистика',
    };

    final tokens = AppTokens.of(context);
    final total = data.total!;
    final children = <Widget>[
      _TotalCard(title: title, summary: total),
      const SizedBox(height: AppSpacing.cardGap),
      _ProfitCard(summary: total),
      const SizedBox(height: AppSpacing.cardGap),
      _LimitCard(
        usedAmount: total.year,
        averageMonthlyIncome: data.averageMonthlyIncome,
      ),
      const SizedBox(height: AppSpacing.cardGap),
      _TaxCard(
        calculator: const TaxCalculator(),
        periodIncome: total.month,
        yearIncome: total.year,
      ),
    ];

    if (filter == DashboardFilter.all) {
      children
        ..add(const SizedBox(height: AppSpacing.cardGap))
        ..add(_SphereCard(
          title: 'IT',
          summary: data.it!,
          accent: tokens.sphereIt,
        ))
        ..add(const SizedBox(height: AppSpacing.cardGap))
        ..add(_SphereCard(
          title: 'Логистика',
          summary: data.logistics!,
          accent: tokens.sphereLogistics,
        ));
    }

    children
      ..add(const SizedBox(height: AppSpacing.cardGap))
      ..add(IncomeChartCard(
        repository: repository,
        now: now,
        sphere: switch (filter) {
          DashboardFilter.all => null,
          DashboardFilter.it => TransactionSphere.it,
          DashboardFilter.logistics => TransactionSphere.logistics,
        },
      ));

    if (documentRepository != null) {
      children
        ..add(const SizedBox(height: AppSpacing.cardGap))
        ..add(TransactionDocumentsCard(
          transactionRepository: repository,
          documentRepository: documentRepository!,
          pdfGenerator: pdfGenerator,
          shareService: shareService,
          fontLoader: fontLoader,
          now: now,
          sphere: switch (filter) {
            DashboardFilter.all => null,
            DashboardFilter.it => TransactionSphere.it,
            DashboardFilter.logistics => TransactionSphere.logistics,
          },
        ));
    }

    return ListView(
      padding: AppSpacing.screen,
      children: children,
    );
  }
}

/// Карточка с акцентной метрикой: заголовок и крупное значение.
class _TotalCard extends StatelessWidget {
  final String title;
  final IncomeSummary summary;

  const _TotalCard({required this.title, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            _MetricRow(
              label: 'Доход за месяц',
              value: summary.month,
              color: tokens.primary,
              emphasized: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricRow(label: 'Доход за год', value: summary.year),
          ],
        ),
      ),
    );
  }
}

class _TaxCard extends StatelessWidget {
  final TaxCalculator calculator;
  final double periodIncome;
  final double yearIncome;

  const _TaxCard({
    required this.calculator,
    required this.periodIncome,
    required this.yearIncome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final period = calculator.calculate(income: periodIncome);
    final year = calculator.calculate(income: yearIncome);

    final limitColor = year.limitExceeded ? tokens.destructive : tokens.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Налог (НПД 6%)', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            _MetricRow(label: 'К уплате за период', value: period.payableTax),
            const SizedBox(height: AppSpacing.xs),
            _MetricRow(label: 'Начислено (6%)', value: period.accruedTax),
            const SizedBox(height: AppSpacing.xs),
            _LimitRow(
              label: 'До лимита НПД',
              yearIncome: year.income,
              exceeded: year.limitExceeded,
              color: limitColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  final String label;
  final double yearIncome;
  final bool exceeded;
  final Color color;

  const _LimitRow({
    required this.label,
    required this.yearIncome,
    required this.exceeded,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining =
        (TaxConstants.limit - yearIncome).clamp(0.0, TaxConstants.limit).toDouble();
    final message =
        exceeded ? 'Лимит НПД превышен' : 'Осталось ${_formatRubles(remaining)}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          message,
          style: theme.textTheme.titleMedium!.copyWith(color: color),
        ),
      ],
    );
  }
}

class _SphereCard extends StatelessWidget {
  final String title;
  final IncomeSummary summary;
  final Color accent;

  const _SphereCard({
    required this.title,
    required this.summary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: AppSpacing.xxs,
                  height: AppSpacing.md,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: AppRadius.chipRadius,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(color: accent),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetricRow(
              label: 'Доход за месяц',
              value: summary.month,
              color: accent,
              emphasized: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricRow(
              label: 'Расход за месяц',
              value: summary.monthExpense,
              color: tokens.destructive,
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricRow(
              label: 'Прибыль за месяц',
              value: summary.monthProfit,
              color: summary.monthProfit < 0 ? tokens.destructive : tokens.success,
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricRow(label: 'Доход за год', value: summary.year),
          ],
        ),
      ),
    );
  }
}

/// Карточка прибыли: доход, расход и прибыль за месяц, прибыль за год.
class _ProfitCard extends StatelessWidget {
  final IncomeSummary summary;

  const _ProfitCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final profitColor =
        summary.monthProfit < 0 ? tokens.destructive : tokens.success;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Прибыль', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            _MetricRow(label: 'Доход за месяц', value: summary.month),
            const SizedBox(height: AppSpacing.xs),
            _MetricRow(
              label: 'Расход за месяц',
              value: summary.monthExpense,
              color: tokens.destructive,
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricRow(
              label: 'Прибыль за месяц',
              value: summary.monthProfit,
              color: profitColor,
              emphasized: true,
            ),
            Divider(height: AppSpacing.lg, color: tokens.border),
            _MetricRow(
              label: 'Прибыль за год',
              value: summary.yearProfit,
              color:
                  summary.yearProfit < 0 ? tokens.destructive : tokens.success,
            ),
          ],
        ),
      ),
    );
  }
}

/// Пустое состояние дашборда, когда операций ещё нет.
class _EmptyState extends StatelessWidget {
  final VoidCallback? onAddOperation;

  const _EmptyState({this.onAddOperation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: AppSpacing.xxl,
              color: tokens.muted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Пока нет операций',
              key: const Key('dashboard_empty'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Добавьте первый доход или расход, чтобы увидеть прибыль, '
              'налог и лимит НПД.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: tokens.muted),
            ),
            if (onAddOperation != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                key: const Key('dashboard_add_operation'),
                onPressed: onAddOperation,
                icon: const Icon(Icons.add),
                label: const Text('Добавить операцию'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LimitCard extends StatelessWidget {
  final double usedAmount;
  final double averageMonthlyIncome;

  const _LimitCard({
    required this.usedAmount,
    required this.averageMonthlyIncome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final result = const LimitCalculator().calculate(
      usedAmount: usedAmount,
      averageMonthlyIncome: averageMonthlyIncome,
    );
    final ratio = result.ratio.clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Лимит НПД', style: theme.textTheme.titleLarge),
                Text(
                  '${LimitCalculator.formatAmount(usedAmount)} ₽ / '
                  '${LimitCalculator.formatAmount(result.limit)} ₽',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _GradientProgressBar(
              key: const Key('limit_progress'),
              value: ratio,
              gradient: tokens.limitGradient,
              trackColor: tokens.surfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              result.text,
              key: const Key('limit_text'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Точность прогноза ±15 дней на горизонте 3 месяцев.',
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Прогноз не учитывает сезонность.',
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Градиентная шкала прогресса (зелёный → жёлтый → красный).
class _GradientProgressBar extends StatelessWidget {
  final double value;
  final LinearGradient gradient;
  final Color trackColor;

  const _GradientProgressBar({
    super.key,
    required this.value,
    required this.gradient,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Semantics(
      value: '${(clamped * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        child: SizedBox(
          height: AppSpacing.md,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: trackColor),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clamped,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: gradient),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  final bool emphasized;

  const _MetricRow({
    required this.label,
    required this.value,
    this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = emphasized
        ? theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.titleMedium;
    final style = color == null ? baseStyle : baseStyle?.copyWith(color: color);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          _formatRubles(value),
          style: style,
          key: Key('summary_$label'),
        ),
      ],
    );
  }
}

String _formatRubles(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '${buffer.toString().replaceAll('.', ',')},${parts[1]} ₽';
}
