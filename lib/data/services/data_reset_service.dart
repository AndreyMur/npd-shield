import '../repositories/contract_draft_repository.dart';
import '../repositories/contractor_profile_repository.dart';
import '../repositories/document_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/risk_report_repository.dart';
import '../repositories/transaction_repository.dart';
import 'activity_spheres_service.dart';
import 'first_run_service.dart';

/// Полная очистка пользовательских данных.
///
/// Удаляет все записи, созданные пользователем, и профиль, а также сбрасывает
/// состояние онбординга — приложение возвращается к виду «как после установки».
/// Встроенные данные приложения (шаблоны договоров и маркеры риска) не
/// затрагиваются: они поставляются вместе с приложением и не являются данными
/// пользователя.
///
/// Справочник клиентов и счета появятся в следующих фазах; их репозитории
/// нужно будет добавить сюда, чтобы очистка оставалась полной.
class DataResetService {
  final TransactionRepository transactionRepository;
  final DocumentRepository documentRepository;
  final ContractDraftRepository contractDraftRepository;
  final RiskReportRepository riskReportRepository;
  final NotificationRepository notificationRepository;
  final ContractorProfileRepository profileRepository;
  final ActivitySpheresService activitySpheresService;
  final FirstRunService firstRunService;

  DataResetService({
    required this.transactionRepository,
    required this.documentRepository,
    required this.contractDraftRepository,
    required this.riskReportRepository,
    required this.notificationRepository,
    required this.profileRepository,
    required this.activitySpheresService,
    required this.firstRunService,
  });

  /// Удаляет все пользовательские данные и возвращает приложение к состоянию
  /// первого запуска.
  Future<void> resetAll() async {
    await transactionRepository.clear();
    await documentRepository.clear();
    await contractDraftRepository.clear();
    await riskReportRepository.clear();
    await notificationRepository.clear();
    await profileRepository.clear();
    await activitySpheresService.reset();
    await firstRunService.reset();
  }
}
