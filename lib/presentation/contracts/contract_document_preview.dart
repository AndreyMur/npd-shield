import 'package:flutter/material.dart';

import '../../domain/contracts/contract_document.dart';

/// Предпросмотр документа договора в реальном времени.
///
/// Отображает разобранный документ ([ComposedContract]) в виде «листа
/// бумаги»: заголовок по центру, заголовки разделов полужирным, обычные
/// абзацы с выравниванием по ширине. Перерисовывается при каждом изменении
/// заполненных полей, поэтому отображает актуальное содержимое документа.
class ContractDocumentPreview extends StatelessWidget {
  /// Разобранный документ с подставленными значениями.
  final ComposedContract document;

  /// Текст, показываемый при пустом документе.
  final String emptyMessage;

  const ContractDocumentPreview({
    super.key,
    required this.document,
    this.emptyMessage = 'Заполните поля, чтобы увидеть предпросмотр договора.',
  });

  @override
  Widget build(BuildContext context) {
    final blocks = document.blocks;
    final hasContent = blocks.any(
      (b) => b.type != ContractBlockType.spacing && b.text.trim().isNotEmpty,
    );

    return Material(
      key: const Key('document_preview'),
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: hasContent
            ? Column(
                key: const Key('document_preview_content'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final block in blocks) ..._buildBlock(context, block),
                ],
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  emptyMessage,
                  key: const Key('document_preview_empty'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
      ),
    );
  }

  List<Widget> _buildBlock(BuildContext context, ContractBlock block) {
    switch (block.type) {
      case ContractBlockType.spacing:
        return [
          SizedBox(height: block.spacingSteps * 10),
        ];
      case ContractBlockType.title:
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              block.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: Colors.black,
              ),
            ),
          ),
        ];
      case ContractBlockType.subtitle:
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              block.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.3,
                color: Colors.black87,
              ),
            ),
          ),
        ];
      case ContractBlockType.heading:
        return [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              block.text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: Colors.black,
              ),
            ),
          ),
        ];
      case ContractBlockType.meta:
        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    block.text,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: Colors.black,
                    ),
                  ),
                ),
                Text(
                  block.secondaryText ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ];
      case ContractBlockType.signature:
        return [
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 8),
            child: Text(
              block.text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.3,
                color: Colors.black,
              ),
            ),
          ),
        ];
      case ContractBlockType.body:
        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              block.text,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 14,
                height: 1.3,
                color: Colors.black87,
              ),
            ),
          ),
        ];
    }
  }
}
