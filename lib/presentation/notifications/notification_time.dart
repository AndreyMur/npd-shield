/// Форматирование времени уведомлений для карточки центра.
///
/// Вынесено из виджетов, чтобы покрывать относительные подписи
/// («только что», «5 мин назад», «вчера») unit-тестами.
library;

const List<String> _monthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

/// Форматирует [date] относительно [now] для отображения в карточке.
///
/// Свежие уведомления показываются относительно («5 мин назад»), вчерашние —
/// с пометкой «вчера», более старые — датой и временем.
String formatNotificationTime(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(date);

  if (difference.isNegative) return _absolute(date, reference);
  if (difference.inMinutes < 1) return 'только что';
  if (difference.inMinutes < 60) return '${difference.inMinutes} мин назад';
  if (_isSameDay(date, reference)) return '${difference.inHours} ч назад';

  final yesterday = reference.subtract(const Duration(days: 1));
  if (_isSameDay(date, yesterday)) return 'вчера, ${_time(date)}';
  return _absolute(date, reference);
}

String _absolute(DateTime date, DateTime reference) {
  final day = '${date.day} ${_monthsGenitive[date.month - 1]}';
  final withYear = date.year == reference.year ? day : '$day ${date.year}';
  return '$withYear, ${_time(date)}';
}

String _time(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
