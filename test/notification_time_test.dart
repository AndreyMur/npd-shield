import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/presentation/notifications/notification_time.dart';

void main() {
  final now = DateTime(2026, 9, 14, 15, 30);

  test('меньше минуты — «только что»', () {
    expect(
      formatNotificationTime(now.subtract(const Duration(seconds: 30)), now: now),
      'только что',
    );
  });

  test('минуты назад', () {
    expect(
      formatNotificationTime(now.subtract(const Duration(minutes: 5)), now: now),
      '5 мин назад',
    );
  });

  test('часы назад в тот же день', () {
    expect(
      formatNotificationTime(now.subtract(const Duration(hours: 3)), now: now),
      '3 ч назад',
    );
  });

  test('вчерашняя дата — «вчера, ЧЧ:ММ»', () {
    expect(
      formatNotificationTime(DateTime(2026, 9, 13, 9, 5), now: now),
      'вчера, 09:05',
    );
  });

  test('в пределах года — день, месяц и время', () {
    expect(
      formatNotificationTime(DateTime(2026, 3, 2, 8, 7), now: now),
      '2 марта, 08:07',
    );
  });

  test('другой год — с годом', () {
    expect(
      formatNotificationTime(DateTime(2025, 12, 31, 23, 59), now: now),
      '31 декабря 2025, 23:59',
    );
  });
}
