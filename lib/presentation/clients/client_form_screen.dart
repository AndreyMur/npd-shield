import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/client.dart';
import '../../data/repositories/client_repository.dart';
import '../../domain/documents/my_tax_deep_link.dart';

/// Форма создания и редактирования карточки клиента из справочника.
///
/// Поля: наименование, ИНН, тип (юрлицо/ИП или физлицо), контакты и заметки.
/// Наименование обязательно; ИНН, если заполнен, должен содержать 10 или 12
/// цифр. При сохранении карточка записывается в репозиторий, а экран
/// возвращает сохранённого клиента (или `null` при отмене).
class ClientFormScreen extends StatefulWidget {
  final ClientRepository repository;

  /// Редактируемый клиент. `null` — создание нового.
  final Client? client;

  const ClientFormScreen({
    super.key,
    required this.repository,
    this.client,
  });

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _innController;
  late final TextEditingController _contactsController;
  late final TextEditingController _notesController;

  late ClientType _type;
  bool _saving = false;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    _nameController = TextEditingController(text: client?.name ?? '');
    _innController = TextEditingController(text: client?.inn ?? '');
    _contactsController = TextEditingController(text: client?.contacts ?? '');
    _notesController = TextEditingController(text: client?.notes ?? '');
    _type = client?.type ?? ClientType.individual;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _innController.dispose();
    _contactsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final existing = widget.client;
    final client = Client(
      name: _nameController.text.trim(),
      inn: _innController.text.trim(),
      type: _type,
      contacts: _contactsController.text.trim(),
      notes: _notesController.text.trim(),
    );

    try {
      if (existing != null) {
        client.id = existing.id;
        await widget.repository.update(client);
      } else {
        await widget.repository.add(client);
      }
      if (!mounted) return;
      Navigator.of(context).pop(client);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить клиента')),
        );
    }
  }

  String? _nameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Укажите наименование или ФИО';
    }
    return null;
  }

  String? _innValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'ИНН должен содержать только цифры';
    }
    if (trimmed.length != 10 && trimmed.length != 12) {
      return 'ИНН: 10 или 12 цифр';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Клиент' : 'Новый клиент'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppTextFormField(
              key: const Key('client_name_field'),
              controller: _nameController,
              validator: _nameValidator,
              textCapitalization: TextCapitalization.words,
              label: 'Наименование или ФИО',
              hint: 'ООО «Ромашка» или Иванов Иван Иванович',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('client_inn_field'),
              controller: _innController,
              validator: _innValidator,
              keyboardType: TextInputType.number,
              label: 'ИНН',
              helper: '10 цифр — юрлицо, 12 — физлицо',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Тип клиента', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<ClientType>(
              key: const Key('client_type_selector'),
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
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextFormField(
              key: const Key('client_contacts_field'),
              controller: _contactsController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              label: 'Контакты',
              hint: 'Телефон, почта, контактное лицо',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              key: const Key('client_notes_field'),
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              label: 'Заметки',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const Key('client_save_button'),
              label: _isEditing ? 'Сохранить' : 'Добавить клиента',
              icon: Icons.check,
              expanded: true,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
