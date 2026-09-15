import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/data/models/app_notification.dart';
import 'package:npd_shield/data/models/contract_draft.dart';
import 'package:npd_shield/data/models/document.dart';
import 'package:npd_shield/data/models/risk_marker.dart';
import 'package:npd_shield/data/models/transaction.dart';
import 'package:npd_shield/data/services/data_reset_service.dart';
import 'package:npd_shield/data/services/first_run_service.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_contract_repositories.dart';
import 'helpers/fake_document_repository.dart';
import 'helpers/fake_notification_repository.dart';
import 'helpers/fake_risk_report_repository.dart';
import 'helpers/fake_transaction_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTransactionRepository transactions;
  late FakeDocumentRepository documents;
  late FakeContractDraftRepository drafts;
  late FakeRiskReportRepository riskReports;
  late FakeNotificationRepository notifications;
  late FakeContractorProfileRepository profile;
  late SharedPrefsFirstRunService firstRun;
  late DataResetService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    transactions = FakeTransactionRepository([
      Transaction(
        amount: 1000,
        date: DateTime(2026, 9, 1),
        sphere: TransactionSphere.it,
        clientName: 'Клиент',
        clientInn: '1234567890',
      ),
    ]);
    documents = FakeDocumentRepository([
      Document(type: DocumentType.receipt, amount: 1000, date: DateTime(2026, 9, 1)),
    ]);
    drafts = FakeContractDraftRepository([
      ContractDraft(templateId: 'it_software_development', filledFields: []),
    ]);
    riskReports = FakeRiskReportRepository([
      RiskReport(sourceName: 'contract.txt', textLength: 100),
    ]);
    notifications = FakeNotificationRepository([
      AppNotification(
        type: NotificationType.limit,
        title: 'Заголовок',
        body: 'Текст',
        createdAt: DateTime(2026, 9, 1),
      ),
    ]);
    profile = FakeContractorProfileRepository(ContractorProfile.demo);
    firstRun = SharedPrefsFirstRunService();
    service = DataResetService(
      transactionRepository: transactions,
      documentRepository: documents,
      contractDraftRepository: drafts,
      riskReportRepository: riskReports,
      notificationRepository: notifications,
      profileRepository: profile,
      firstRunService: firstRun,
    );
  });

  group('DataResetService', () {
    test('resetAll очищает все пользовательские данные и профиль', () async {
      await service.resetAll();

      expect(transactions.transactions, isEmpty);
      expect(documents.documents, isEmpty);
      expect(drafts.drafts, isEmpty);
      expect(riskReports.reports, isEmpty);
      expect(notifications.notifications, isEmpty);
      expect(profile.profile, isNull);
    });

    test('resetAll возвращает состояние первого запуска', () async {
      await firstRun.completeOnboarding(StartMode.demo);

      await service.resetAll();

      expect(await firstRun.isOnboardingCompleted(), isFalse);
      expect(await firstRun.getStartMode(), isNull);
    });
  });
}
