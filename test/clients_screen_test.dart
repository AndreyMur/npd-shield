import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/client.dart';
import 'package:npd_shield/domain/documents/my_tax_deep_link.dart';
import 'package:npd_shield/presentation/clients/clients_screen.dart';

import 'helpers/fake_client_repository.dart';
import 'helpers/fake_document_repository.dart';
import 'helpers/fake_transaction_repository.dart';

void main() {
  Client client({
    int? id,
    String name = 'ООО «Альфа»',
    String inn = '7701234567',
    ClientType type = ClientType.legal,
    String contacts = '',
    String notes = '',
  }) {
    final value = Client(
      name: name,
      inn: inn,
      type: type,
      contacts: contacts,
      notes: notes,
    );
    if (id != null) value.id = id;
    return value;
  }

  Future<void> pumpClients(
    WidgetTester tester,
    FakeClientRepository repository,
  ) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ClientsScreen(
          repository: repository,
          transactionRepository: FakeTransactionRepository(),
          documentRepository: FakeDocumentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows empty state when there are no clients', (tester) async {
    await pumpClients(tester, FakeClientRepository());

    expect(find.byKey(const Key('clients_empty')), findsOneWidget);
    expect(find.text('Клиентов пока нет'), findsOneWidget);
  });

  testWidgets('lists clients and searches by name and INN', (tester) async {
    final repo = FakeClientRepository([
      client(id: 1, name: 'ООО «Альфа»', inn: '7701234567'),
      client(
        id: 2,
        name: 'Петров Пётр',
        inn: '770987654321',
        type: ClientType.individual,
      ),
    ]);
    await pumpClients(tester, repo);

    expect(find.text('ООО «Альфа»'), findsOneWidget);
    expect(find.text('Петров Пётр'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('clients_search_field')),
      'альфа',
    );
    await tester.pumpAndSettle();
    expect(find.text('ООО «Альфа»'), findsOneWidget);
    expect(find.text('Петров Пётр'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('clients_search_field')),
      '770987654321',
    );
    await tester.pumpAndSettle();
    expect(find.text('Петров Пётр'), findsOneWidget);
    expect(find.text('ООО «Альфа»'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('clients_search_field')),
      'несуществующий',
    );
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
  });

  testWidgets('creates a client from the form', (tester) async {
    final repo = FakeClientRepository();
    await pumpClients(tester, repo);

    await tester.tap(find.byKey(const Key('clients_add_button')));
    await tester.pumpAndSettle();
    expect(find.text('Новый клиент'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('client_name_field')),
      'ИП Смирнов',
    );
    await tester.enterText(
      find.byKey(const Key('client_inn_field')),
      '770123456789',
    );
    await tester.tap(find.byKey(const Key('client_save_button')));
    await tester.pumpAndSettle();

    expect(repo.clients, hasLength(1));
    expect(repo.clients.single.name, 'ИП Смирнов');
    expect(find.text('ИП Смирнов'), findsOneWidget);
  });

  testWidgets('validates required name and INN format', (tester) async {
    final repo = FakeClientRepository();
    await pumpClients(tester, repo);

    await tester.tap(find.byKey(const Key('clients_add_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('client_save_button')));
    await tester.pumpAndSettle();
    expect(find.text('Укажите наименование или ФИО'), findsOneWidget);
    expect(repo.clients, isEmpty);

    await tester.enterText(
      find.byKey(const Key('client_name_field')),
      'ООО «Тест»',
    );
    await tester.enterText(
      find.byKey(const Key('client_inn_field')),
      '123',
    );
    await tester.tap(find.byKey(const Key('client_save_button')));
    await tester.pumpAndSettle();
    expect(find.text('ИНН: 10 или 12 цифр'), findsOneWidget);
    expect(repo.clients, isEmpty);
  });

  testWidgets('opens the client card and edits it', (tester) async {
    final repo = FakeClientRepository([client(id: 1, name: 'ООО «Альфа»')]);
    await pumpClients(tester, repo);

    await tester.tap(find.byKey(const Key('client_entry_1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('client_details_name')), findsOneWidget);

    await tester.tap(find.byKey(const Key('client_details_edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('client_name_field')),
      'ООО «Бета»',
    );
    await tester.tap(find.byKey(const Key('client_save_button')));
    await tester.pumpAndSettle();

    expect(repo.clients.single.name, 'ООО «Бета»');
    expect(find.text('ООО «Бета»'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('ООО «Бета»'), findsOneWidget);
  });

  testWidgets('deletes a client after confirmation and restores with undo', (
    tester,
  ) async {
    final repo = FakeClientRepository([client(id: 1, name: 'ООО «Альфа»')]);
    await pumpClients(tester, repo);

    await tester.tap(find.byKey(const Key('client_delete_1')));
    await tester.pumpAndSettle();
    expect(find.text('Удалить клиента?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('client_delete_cancel')));
    await tester.pumpAndSettle();
    expect(repo.clients, hasLength(1));

    await tester.tap(find.byKey(const Key('client_delete_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('client_delete_confirm')));
    await tester.pumpAndSettle();

    expect(repo.clients, isEmpty);
    expect(find.byKey(const Key('clients_empty')), findsOneWidget);
    expect(find.text('Клиент удалён'), findsOneWidget);

    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();
    expect(repo.clients, hasLength(1));
    expect(find.text('ООО «Альфа»'), findsOneWidget);
  });
}
