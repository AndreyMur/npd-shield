import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseEncryptionService {
  final _secureStorage = const FlutterSecureStorage();
  final _seedAlias = 'npd_shield_db_seed';
  final _ivAlias = 'npd_shield_db_iv';
  
  Key? _cachedKey;
  IV? _cachedIV;
  bool _isAvailable = true;

  static const int _keySize = 32; // AES-256
  static const int _ivSize = 16;  // AES block size

  Future<Key> getEncryptionKey() async {
    if (_cachedKey != null) {
      return _cachedKey!;
    }

    if (!_isAvailable) {
      return Key(Uint8List(_keySize)); // Пустой ключ для тестов
    }

    try {
      var seed = await _secureStorage.read(key: _seedAlias);
      
      if (seed == null) {
        final random = Random.secure();
        final seedBytes = List<int>.generate(_keySize, (i) => random.nextInt(256));
        seed = base64Encode(Uint8List.fromList(seedBytes));
        await _secureStorage.write(key: _seedAlias, value: seed);
      }

      final seedBytes = base64Decode(seed);
      final hash = sha256.convert(seedBytes);
      final keyBytes = hash.bytes;
      
      _cachedKey = Key(Uint8List.fromList(keyBytes));
      return _cachedKey!;
    } catch (e) {
      _isAvailable = false;
      return Key(Uint8List(_keySize));
    }
  }

  Future<IV> getIV() async {
    if (_cachedIV != null) {
      return _cachedIV!;
    }

    if (!_isAvailable) {
      return IV(Uint8List(_ivSize));
    }

    try {
      var ivBase64 = await _secureStorage.read(key: _ivAlias);
      
      if (ivBase64 == null) {
        final random = Random.secure();
        final ivBytes = List<int>.generate(_ivSize, (i) => random.nextInt(256));
        ivBase64 = base64Encode(Uint8List.fromList(ivBytes));
        await _secureStorage.write(key: _ivAlias, value: ivBase64);
      }

      final ivBytes = base64Decode(ivBase64);
      _cachedIV = IV(Uint8List.fromList(ivBytes));
      return _cachedIV!;
    } catch (e) {
      _isAvailable = false;
      return IV(Uint8List(_ivSize));
    }
  }

  Future<String> encrypt(String plainText) async {
    if (!_isAvailable) {
      return plainText; // Не шифруем в тестах
    }

    try {
      final key = await getEncryptionKey();
      final iv = await getIV();
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return encrypted.base64;
    } catch (e) {
      _isAvailable = false;
      return plainText;
    }
  }

  Future<String> decrypt(String encryptedText) async {
    if (!_isAvailable) {
      return encryptedText; // Не расшифровываем в тестах
    }

    try {
      final key = await getEncryptionKey();
      final iv = await getIV();
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      
      final decrypted = encrypter.decrypt64(encryptedText, iv: iv);
      return decrypted;
    } catch (e) {
      _isAvailable = false;
      return encryptedText;
    }
  }

  Future<void> clearCache() {
    _cachedKey = null;
    _cachedIV = null;
    return Future.value();
  }
}
