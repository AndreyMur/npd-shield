import 'dart:convert';

/// Максимальный размер проверяемого TXT-файла — 100 КБ.
const int maxRiskContractFileBytes = 100 * 1024;

/// Исключение: выбранный файл превышает допустимый размер.
class ContractFileTooLargeException implements Exception {
  /// Фактический размер файла в байтах.
  final int actualBytes;

  /// Допустимый размер файла в байтах.
  final int maxBytes;

  const ContractFileTooLargeException({
    required this.actualBytes,
    this.maxBytes = maxRiskContractFileBytes,
  });

  @override
  String toString() =>
      'Файл $actualBytes Б превышает лимит $maxBytes Б';
}

/// Длина [content] в байтах UTF-8.
int riskContractByteLength(String content) => utf8.encode(content).length;

/// Помещается ли текст договора в лимит 100 КБ.
bool isRiskContractWithinLimit(String content) =>
    riskContractByteLength(content) <= maxRiskContractFileBytes;
