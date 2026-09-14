import 'package:flutter/material.dart';

import '../../domain/documents/my_tax_deep_link.dart';
import '../../domain/documents/my_tax_deep_link_service.dart';

/// Экран перехода в приложение «Мой налог».
///
/// Показывает данные расчёта, позволяет выбрать тип покупателя и открыть
/// «Мой налог» по deep link. Если приложение не установлено, данные
/// копируются в буфер обмена и показывается инструкция по ручному вводу.
class MyTaxDeepLinkScreen extends StatefulWidget {
  /// Данные расчёта для передачи в «Мой налог».
  final MyTaxDeepLink link;

  /// Сервис открытия deep link и копирования в буфер обмена.
  final MyTaxDeepLinkService service;

  const MyTaxDeepLinkScreen({
    super.key,
    required this.link,
    this.service = const MyTaxDeepLinkService(),
  });

  @override
  State<MyTaxDeepLinkScreen> createState() => _MyTaxDeepLinkScreenState();
}

class _MyTaxDeepLinkScreenState extends State<MyTaxDeepLinkScreen> {
  late ClientType _clientType;
  bool _busy = false;

  /// Был ли выполнен fallback с копированием данных в буфер обмена.
  bool _fallback = false;

  @override
  void initState() {
    super.initState();
    _clientType = widget.link.clientType;
  }

  MyTaxDeepLink get _link => widget.link.copyWith(clientType: _clientType);

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await widget.service.open(_link);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _fallback = result.copied;
      });
      _showSnack(
        result.opened
            ? 'Открываем «Мой налог»…'
            : 'Данные скопированы. Вставьте их в «Мой налог»',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showSnack('Не удалось открыть «Мой налог»');
    }
  }

  Future<void> _copy() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.service.copy(_link);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _fallback = true;
      });
      _showSnack('Данные скопированы. Вставьте их в «Мой налог»');
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showSnack('Не удалось скопировать данные');
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
      appBar: AppBar(title: const Text('«Мой налог»')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildSummaryCard(theme),
            const SizedBox(height: 20),
            Text('Тип покупателя', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<ClientType>(
              key: const Key('my_tax_client_type'),
              segments: [
                for (final type in ClientType.values)
                  ButtonSegment(
                    value: type,
                    label: Text(type.label),
                    icon: Icon(
                      type == ClientType.legal
                          ? Icons.business_outlined
                          : Icons.person_outline,
                    ),
                  ),
              ],
              selected: {_clientType},
              onSelectionChanged: _busy
                  ? null
                  : (selection) => setState(() => _clientType = selection.first),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('my_tax_open_button'),
              onPressed: _busy ? null : _open,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.open_in_new),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Открыть «Мой налог»'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('my_tax_copy_button'),
              onPressed: _busy ? null : _copy,
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Скопировать данные'),
            ),
            if (_fallback) ...[
              const SizedBox(height: 16),
              _buildFallbackNotice(theme),
            ],
            const SizedBox(height: 20),
            _buildInstruction(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final link = _link;
    final subtitle = [
      if (link.clientName.trim().isNotEmpty) link.clientName.trim(),
      if (link.clientInn.trim().isNotEmpty) 'ИНН ${link.clientInn.trim()}',
      link.clientType.label,
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
                  Icons.receipt_long_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    link.serviceName.trim().isEmpty
                        ? 'Расчёт для «Мой налог»'
                        : link.serviceName.trim(),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Сумма: ${link.formattedAmount}',
              key: const Key('my_tax_summary_amount'),
              style: theme.textTheme.bodyLarge,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackNotice(ThemeData theme) {
    return Card(
      key: const Key('my_tax_fallback_notice'),
      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.tertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Приложение «Мой налог» не найдено. Данные скопированы в '
                'буфер обмена — вставьте их в приложении вручную.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(ThemeData theme) {
    return Card(
      key: const Key('my_tax_instruction'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Как ввести данные вручную',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final step in _link.manualSteps)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•', style: theme.textTheme.bodyMedium),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(step, style: theme.textTheme.bodyMedium),
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
