import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/document.dart';
import '../../domain/documents/receipt.dart';

/// Единая карточка документа архива: чек, акт или договор.
///
/// Показывает тип, статус, контрагента, сумму и дату документа, а для акта —
/// его связи с договором ([linkedContractNumber]) и чеком ([linkedReceipt]).
/// Карточка переиспользуется экраном акта и будущим архивом документов.
class DocumentCard extends StatelessWidget {
  final Document document;

  /// Номер связанного договора (если акт привязан к договору).
  final String linkedContractNumber;

  /// Связанный чек (если акт привязан к чеку).
  final Document? linkedReceipt;

  final VoidCallback? onTap;

  const DocumentCard({
    super.key,
    required this.document,
    this.linkedContractNumber = '',
    this.linkedReceipt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final hasLinks =
        linkedContractNumber.trim().isNotEmpty || linkedReceipt != null;
    final title = document.serviceName.isEmpty
        ? document.type.label
        : document.serviceName;

    return AppCard(
      key: Key('document_card_${document.type.name}'),
      onTap: onTap,
      semanticLabel:
          '${document.type.label}. $title. ${document.status.label}. '
          '${formatReceiptAmount(document.amount)}. '
          '${formatContractDate(document.date)}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(document.type), color: tokens.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                document.type.label,
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              _StatusChip(status: document.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: theme.textTheme.bodyLarge),
          if (document.counterpartyName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              document.counterpartyName,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '${formatReceiptAmount(document.amount)} · '
            '${formatContractDate(document.date)}',
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
          ),
          if (hasLinks) ...[
            Divider(height: AppSpacing.lg, color: tokens.border),
            Text(
              'Связанные документы',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            if (linkedContractNumber.trim().isNotEmpty)
              _LinkRow(
                key: const Key('document_link_contract'),
                icon: Icons.description_outlined,
                label: 'Договор № $linkedContractNumber',
              ),
            if (linkedReceipt != null)
              _LinkRow(
                key: const Key('document_link_receipt'),
                icon: Icons.receipt_long_outlined,
                label:
                    'Чек от ${formatContractDate(linkedReceipt!.date)} · '
                    '${formatReceiptAmount(linkedReceipt!.amount)}',
              ),
          ],
        ],
      ),
    );
  }

  static IconData _iconFor(DocumentType type) {
    return switch (type) {
      DocumentType.receipt => Icons.receipt_long_outlined,
      DocumentType.act => Icons.assignment_turned_in_outlined,
      DocumentType.contract => Icons.description_outlined,
    };
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LinkRow({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: tokens.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final DocumentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final color = switch (status) {
      DocumentStatus.draft => tokens.muted,
      DocumentStatus.generated => tokens.primary,
      DocumentStatus.sent => tokens.secondary,
    };
    return AppStatusChip(label: status.label, color: color);
  }
}
