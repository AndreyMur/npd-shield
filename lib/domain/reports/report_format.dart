/// Форматирование значений отчёта для интерфейса и файлов экспорта.
///
/// Отчётность на русском языке использует разделитель разрядов — пробел,
/// десятичный разделитель — запятую, даты — в формате `дд.мм.гггг`. Единые
/// функции нужны, чтобы PDF-отчёт и CSV-выгрузка выглядели одинаково.
library;

/// Форматирует дату как `дд.мм.гггг`.
String formatReportDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

/// Форматирует дату и время как `дд.мм.гггг чч:мм`.
String formatReportDateTime(DateTime date) {
  final hours = date.hour.toString().padLeft(2, '0');
  final minutes = date.minute.toString().padLeft(2, '0');
  return '${formatReportDate(date)} $hours:$minutes';
}

/// Форматирует сумму как `1 234 567,89` (пробел — разряды, запятая — копейки).
String formatReportAmount(double value) {
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  final sign = value < 0 ? '-' : '';
  return '$sign$buffer,${parts.last}';
}

/// Форматирует сумму с символом рубля: `1 234,56 ₽`.
String formatReportMoney(double value) => '${formatReportAmount(value)} ₽';
