import 'package:isar/isar.dart';

import '../models/transaction.dart';
import 'transaction_repository.dart';

class IsarTransactionRepository implements TransactionRepository {
  final Isar isar;
  final _cache = _OptimizedCache();

  IsarTransactionRepository(this.isar);

  @override
  Future<int> add(Transaction transaction) {
    return isar.writeTxn(() async {
      final id = await isar.transactions.put(transaction);
      _cache.invalidate();
      return id;
    });
  }

  @override
  Future<List<Transaction>> getAll() {
    return isar.transactions.where().findAll();
  }

  @override
  Future<List<Transaction>> getAllForSphere(TransactionSphere sphere) {
    return isar.transactions.where().sphereEqualTo(sphere).findAll();
  }

  @override
  Future<IncomeSummary> getIncomeSummary({
    TransactionSphere? sphere,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final monthStart = DateTime(today.year, today.month);
    final yearStart = DateTime(today.year);
    final cacheKey = _CacheKey('summary', sphere, monthStart, yearStart);

    final cached = _cache.getSummary(cacheKey);
    if (cached != null) {
      return Future.value(cached);
    }

    return isar.txn(() async {
      final all = sphere != null
          ? await isar.transactions.where().sphereEqualTo(sphere).findAll()
          : await isar.transactions.where().findAll();

      double month = 0;
      double year = 0;
      for (final t in all) {
        if (!t.date.isBefore(monthStart)) {
          month += t.amount;
        }
        if (!t.date.isBefore(yearStart)) {
          year += t.amount;
        }
      }

      final result = IncomeSummary(month: month, year: year);
      _cache.setSummary(cacheKey, result);
      return result;
    });
  }

  @override
  Future<double> getAverageMonthlyIncome({
    TransactionSphere? sphere,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final start = DateTime(today.year, today.month - 2);
    final end = DateTime(today.year, today.month + 1);
    final cacheKey = _CacheKey('average', sphere, start, end);

    final cached = _cache.getAverage(cacheKey);
    if (cached != null) {
      return Future.value(cached);
    }

    return isar.txn(() async {
      final all = sphere != null
          ? await isar.transactions.where().sphereEqualTo(sphere).findAll()
          : await isar.transactions.where().findAll();

      double total = 0;
      for (final t in all) {
        if (!t.date.isBefore(start) && t.date.isBefore(end)) {
          total += t.amount;
        }
      }

      final result = total / 3;
      _cache.setAverage(cacheKey, result);
      return result;
    });
  }

  @override
  Future<List<IncomePoint>> getIncomeSeries({
    SeriesPeriod period = SeriesPeriod.month,
    TransactionSphere? sphere,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final lastBucketStart = startOfBucket(period, today);
    final starts = [
      for (var i = period.bucketCount - 1; i >= 0; i--)
        subtractBuckets(period, lastBucketStart, i),
    ];
    final cacheKey = _CacheKey('series-$period', sphere, starts.first, starts.last);

    final cached = _cache.getSeries(cacheKey);
    if (cached != null) {
      return Future.value(cached);
    }

    final amounts = List<double>.filled(starts.length, 0);

    return isar.txn(() async {
      final all = sphere != null
          ? await isar.transactions.where().sphereEqualTo(sphere).findAll()
          : await isar.transactions.where().findAll();

      final firstIndex = bucketIndex(period, starts.first);
      for (final t in all) {
        final index =
            bucketIndex(period, startOfBucket(period, t.date)) - firstIndex;
        if (index >= 0 && index < starts.length) {
          amounts[index] += t.amount;
        }
      }

      final result = [
        for (var i = 0; i < starts.length; i++)
          IncomePoint(start: starts[i], amount: amounts[i]),
      ];
      _cache.setSeries(cacheKey, result);
      return result;
    });
  }

  @override
  Future<void> clear() {
    return isar.writeTxn(() async {
      await isar.transactions.clear();
      _cache.invalidate();
    });
  }
}

class _CacheKey {
  final String type;
  final TransactionSphere? sphere;
  final DateTime start;
  final DateTime end;

  _CacheKey(this.type, this.sphere, this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CacheKey &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          sphere == other.sphere &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(type, sphere, start, end);

  String toCompositeKey() => '$type:$sphere:${start.millisecondsSinceEpoch}:${end.millisecondsSinceEpoch}';
}

class _OptimizedCache {
  final _summaryCache = <String, IncomeSummary>{};
  final _averageCache = <String, double>{};
  final _seriesCache = <String, List<IncomePoint>>{};
  final _stopwatch = Stopwatch();

  _OptimizedCache() {
    _stopwatch.start();
  }

  IncomeSummary? getSummary(_CacheKey key) {
    if (!_stopwatch.isRunning) return null;
    return _summaryCache[key.toCompositeKey()];
  }

  void setSummary(_CacheKey key, IncomeSummary value) {
    _summaryCache[key.toCompositeKey()] = value;
  }

  double? getAverage(_CacheKey key) {
    if (!_stopwatch.isRunning) return null;
    return _averageCache[key.toCompositeKey()];
  }

  void setAverage(_CacheKey key, double value) {
    _averageCache[key.toCompositeKey()] = value;
  }

  List<IncomePoint>? getSeries(_CacheKey key) {
    if (!_stopwatch.isRunning) return null;
    return _seriesCache[key.toCompositeKey()];
  }

  void setSeries(_CacheKey key, List<IncomePoint> value) {
    _seriesCache[key.toCompositeKey()] = value;
  }

  void invalidate() {
    _summaryCache.clear();
    _averageCache.clear();
    _seriesCache.clear();
  }
}

DateTime startOfBucket(SeriesPeriod period, DateTime date) {
  return switch (period) {
    SeriesPeriod.week =>
      DateTime(date.year, date.month, date.day)
          .subtract(Duration(days: date.weekday - 1)),
    SeriesPeriod.month => DateTime(date.year, date.month),
    SeriesPeriod.quarter =>
      DateTime(date.year, ((date.month - 1) ~/ 3) * 3 + 1),
    SeriesPeriod.year => DateTime(date.year),
  };
}

DateTime subtractBuckets(SeriesPeriod period, DateTime start, int count) {
  return switch (period) {
    SeriesPeriod.week => start.subtract(Duration(days: 7 * count)),
    SeriesPeriod.month => DateTime(start.year, start.month - count, start.day),
    SeriesPeriod.quarter =>
      DateTime(start.year, start.month - 3 * count, start.day),
    SeriesPeriod.year => DateTime(start.year - count, start.month, start.day),
  };
}

int bucketIndex(SeriesPeriod period, DateTime bucketStart) {
  return switch (period) {
    SeriesPeriod.week =>
      DateTime.utc(
        bucketStart.year,
        bucketStart.month,
        bucketStart.day,
      ).millisecondsSinceEpoch ~/
          (7 * Duration.millisecondsPerDay),
    SeriesPeriod.month => bucketStart.year * 12 + bucketStart.month,
    SeriesPeriod.quarter => (bucketStart.year * 12 + bucketStart.month) ~/ 3,
    SeriesPeriod.year => bucketStart.year,
  };
}
