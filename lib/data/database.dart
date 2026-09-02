import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/transaction.dart';

class AppDatabase {
  AppDatabase._();

  static late Isar instance;

  static Future<Isar> open({String? path}) async {
    final isarDir = path ?? (await getApplicationDocumentsDirectory()).path;
    
    instance = await Isar.open(
      [TransactionSchema],
      directory: isarDir,
      name: 'npd_shield',
    );
    return instance;
  }
}
