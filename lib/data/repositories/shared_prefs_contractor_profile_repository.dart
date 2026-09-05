import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/profile/contractor_profile.dart';
import '../security/database_encryption_service.dart';
import '../security/field_encryption_service.dart';
import 'contractor_profile_repository.dart';

class SharedPrefsContractorProfileRepository
    implements ContractorProfileRepository {
  static const _prefsKey = 'contractor_profile';
  final FieldEncryptionService _encryptionService;

  SharedPrefsContractorProfileRepository({FieldEncryptionService? encryption})
    : _encryptionService = encryption ?? DatabaseEncryptionService();

  @override
  Future<ContractorProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return null;
    try {
      final decrypted = await _encryptionService.decrypt(raw);
      return ContractorProfile.fromJson(
        jsonDecode(decrypted) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(ContractorProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(profile.toJson());
    await prefs.setString(_prefsKey, await _encryptionService.encrypt(json));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  @override
  Future<void> seedDemoIfEmpty() async {
    if (await load() == null) {
      await save(ContractorProfile.demo);
    }
  }
}
