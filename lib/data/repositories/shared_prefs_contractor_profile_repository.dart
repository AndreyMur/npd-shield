import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/profile/contractor_profile.dart';
import 'contractor_profile_repository.dart';

class SharedPrefsContractorProfileRepository
    implements ContractorProfileRepository {
  static const _prefsKey = 'contractor_profile';

  @override
  Future<ContractorProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return null;
    try {
      return ContractorProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(ContractorProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(profile.toJson()));
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
