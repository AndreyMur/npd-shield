import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/core/theme/app_theme.dart';
import 'package:npd_shield/core/theme/app_tokens.dart';
import 'package:npd_shield/core/widgets/widgets.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/repositories/transaction_repository.dart';
import 'package:npd_shield/presentation/invoices/invoices_screen.dart';
import 'package:npd_shield/presentation/notifications/notification_center_screen.dart';
import 'package:npd_shield/presentation/operations/operations_screen.dart';

import 'helpers/fake_invoice_repository.dart';
import 'helpers/fake_notification_repository.dart';
import 'helpers/fake_transaction_repository.dart';

/// Репозиторий, который всегда падает при загрузке — для проверки error-state.
class _FailingTransactionRepository extends FakeTransactionRepository {
  @override
  Future<List<Transaction>> getAll({TransactionFilter? filter}) async {
    throw Exception('load failed');
  }
}

void main() {
  final now = DateTime(2026, 9, 16);

  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Transaction tx({
    int id = 1,
    double amount = 1000,
    String client = 'Альфа',
  }) {
    final value = Transaction(
      amount: amount,
      date: DateTime(2026, 9, 10),
      sphere: TransactionSphere.it,
      type: TransactionType.income,
      clientName: client,
      clientInn: '',
    );
    value.id = id;
    return value;
  }

  group('Единые empty/loading/error', () {
    testWidgets('операции: пустое состояние — AppEmptyState', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: OperationsScreen(
            repository: FakeTransactionRepository(),
            now: now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Операций пока нет'), findsOneWidget);
    });

    testWidgets('операции: ошибка — AppErrorState с повтором', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: OperationsScreen(
            repository: _FailingTransactionRepository(),
            now: now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.byKey(const Key('operations_retry')), findsOneWidget);
      expect(find.text('Не удалось загрузить операции'), findsOneWidget);
    });

    testWidgets('уведомления: ошибка — AppErrorState с повтором', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationCenterScreen(
            repository: FakeNotificationRepository.failing(),
            clock: () => now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.byKey(const Key('notification_center_retry')), findsOneWidget);
    });

    testWidgets('счета: пустое состояние — AppEmptyState', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: InvoicesScreen(
            repository: FakeInvoiceRepository(),
            now: now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Счетов пока нет'), findsOneWidget);
    });

    testWidgets('загрузка показывает shimmer-skeleton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppLoadingState()),
        ),
      );
      await tester.pump();

      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(Shimmer), findsOneWidget);
    });
  });

  group('Semantic labels и pressed-state', () {
    testWidgets('карточка операции имеет semantic-метку', (tester) async {
      final handle = tester.ensureSemantics();
      setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: OperationsScreen(
            repository: FakeTransactionRepository([tx()]),
            now: now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('Доход.*Альфа')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('AppCard с onTap даёт pressed-state (AnimatedScale)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () {},
              child: const Text('Карточка'),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedScale), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });
  });

  group('Обе темы', () {
    testWidgets('экран операций рендерится в light и dark без ошибок',
        (tester) async {
      setViewport(tester);
      for (final theme in [AppTheme.light(null), AppTheme.dark(null)]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: OperationsScreen(
              repository: FakeTransactionRepository([tx()]),
              now: now,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('operations_list')), findsOneWidget);
      }
    });
  });

  group('Компоненты дизайн-системы', () {
    testWidgets('AppButton primary вызывает onPressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Добавить',
              icon: Icons.add,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Добавить'));
      expect(tapped, isTrue);
    });

    testWidgets('AppFilterChip переключается по нажатию', (tester) async {
      var selected = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => AppFilterChip(
                label: 'IT',
                selected: selected,
                onSelected: () => setState(() => selected = true),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('IT'));
      await tester.pumpAndSettle();
      final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip));
      expect(chip.selected, isTrue);
    });

    testWidgets('StatusBanner danger использует семантический цвет',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: StatusBanner(
              type: StatusBannerType.danger,
              message: 'Просрочено',
            ),
          ),
        ),
      );

      expect(find.text('Просрочено'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('AppMetricCard показывает подпись и значение', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppMetricCard(
              label: 'Доход',
              value: '1 000,00 ₽',
              accent: AppTokens.light.success,
            ),
          ),
        ),
      );

      expect(find.text('Доход'), findsOneWidget);
      expect(find.text('1 000,00 ₽'), findsOneWidget);
    });
  });

  group('Консистентность токенов', () {
    test('в экранах фазы 34 нет хардкод-цветов', () {
      const files = [
        'lib/presentation/operations/operations_screen.dart',
        'lib/presentation/operations/transaction_form_screen.dart',
        'lib/presentation/clients/clients_screen.dart',
        'lib/presentation/clients/client_details_screen.dart',
        'lib/presentation/clients/client_form_screen.dart',
        'lib/presentation/clients/client_picker.dart',
        'lib/presentation/invoices/invoices_screen.dart',
        'lib/presentation/invoices/invoice_form_screen.dart',
        'lib/presentation/invoices/invoice_payment_dialog.dart',
        'lib/presentation/invoices/invoice_status_visuals.dart',
        'lib/presentation/documents/document_archive_screen.dart',
        'lib/presentation/documents/document_card.dart',
        'lib/presentation/notifications/notification_center_screen.dart',
        'lib/presentation/notifications/notification_card.dart',
      ];

      final colorPattern = RegExp(r'Color\(0x');
      final materialColorPattern = RegExp(r'\bColors\.');
      for (final path in files) {
        final source = File(path).readAsStringSync();
        expect(
          colorPattern.hasMatch(source),
          isFalse,
          reason: '$path содержит хардкод-цвет Color(0x...)',
        );
        expect(
          materialColorPattern.hasMatch(source),
          isFalse,
          reason: '$path содержит Material-цвет Colors.*',
        );
      }
    });

    test('semantic-состояния используют общие компоненты', () {
      const files = [
        'lib/presentation/operations/operations_screen.dart',
        'lib/presentation/clients/clients_screen.dart',
        'lib/presentation/invoices/invoices_screen.dart',
        'lib/presentation/documents/document_archive_screen.dart',
        'lib/presentation/notifications/notification_center_screen.dart',
      ];

      for (final path in files) {
        final source = File(path).readAsStringSync();
        expect(
          source.contains('AppEmptyState'),
          isTrue,
          reason: '$path должен использовать AppEmptyState',
        );
        expect(
          source.contains('AppErrorState'),
          isTrue,
          reason: '$path должен использовать AppErrorState',
        );
        expect(
          source.contains('AppLoadingState'),
          isTrue,
          reason: '$path должен использовать AppLoadingState',
        );
      }
    });
  });
}
