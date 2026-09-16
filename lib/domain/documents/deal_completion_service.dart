import '../../data/models/document.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/document_repository.dart';
import '../profile/contractor_profile.dart';
import 'receipt.dart';

/// Результат завершения сделки: сформированный чек и его запись в архиве.
class CompletedDeal {
  final Receipt receipt;
  final Document document;

  const CompletedDeal({required this.receipt, required this.document});
}

/// Завершение сделки: автоформирование чека и сохранение его в архив.
///
/// Отделяет бизнес-логику завершения сделки от интерфейса: реквизиты чека
/// собираются из профиля ИП и договора/транзакции, а запись документа
/// сохраняется в архиве. Один и тот же сервис используется экраном завершения
/// сделки и тестами.
class DealCompletionService {
  final ReceiptGenerator generator;

  const DealCompletionService({this.generator = const ReceiptGenerator()});

  /// Формирует чек по данным договора/транзакции и сохраняет его в архив.
  Future<CompletedDeal> completeDeal({
    required ContractorProfile profile,
    required DocumentRepository documentRepository,
    Map<String, String> contractFields = const {},
    int contractDraftId = 0,
    Transaction? transaction,
    int transactionId = 0,
    int clientId = 0,
    DateTime? date,
  }) async {
    final receipt = generator.generate(
      profile: profile,
      contractFields: contractFields,
      transaction: transaction,
      contractDraftId: contractDraftId,
      transactionId: transactionId,
      clientId: clientId,
      date: date,
    );
    return saveReceipt(receipt: receipt, documentRepository: documentRepository);
  }

  /// Сохраняет уже сформированный чек в архив документов.
  Future<CompletedDeal> saveReceipt({
    required Receipt receipt,
    required DocumentRepository documentRepository,
  }) async {
    final document = receipt.toDocument();
    document.id = await documentRepository.save(document);
    return CompletedDeal(receipt: receipt, document: document);
  }
}
