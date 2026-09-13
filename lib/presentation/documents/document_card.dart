import 'package:flutter/material.dart';

import '../../core/constants/contract_field_keys.dart';
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
    final hasLinks =
        linkedContractNumber.trim().isNotEmpty || linkedReceipt != null;

    return Card(
      key: Key('document_card_${document.type.name}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconFor(document.type), color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    document.type.label,
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  _StatusChip(status: document.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                document.serviceName.isEmpty
                    ? document.type.label
                    : document.serviceName,
                style: theme.textTheme.bodyLarge,
              ),
              if (document.counterpartyName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  document.counterpartyName,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 6),
              Text(
                '${formatReceiptAmount(document.amount)} · '
                '${formatContractDate(document.date)}',
                style: theme.textTheme.bodySmall,
              ),
              if (hasLinks) ...[
                const Divider(height: 24),
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
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
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
    final theme = Theme.of(context);
    final color = switch (status) {
      DocumentStatus.draft => theme.colorScheme.outline,
      DocumentStatus.generated => theme.colorScheme.primary,
      DocumentStatus.sent => theme.colorScheme.tertiary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
