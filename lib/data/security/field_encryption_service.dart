/// Шифрование чувствительных строковых значений при хранении.
///
/// Реализация по умолчанию — [DatabaseEncryptionService] (AES-256, ключ
/// в flutter_secure_storage). Интерфейс позволяет подменять шифрование в
/// тестах детерминированной реализацией.
abstract class FieldEncryptionService {
  /// Шифрует [plainText] и возвращает строку для хранения.
  Future<String> encrypt(String plainText);

  /// Расшифровывает [encryptedText] в исходный текст.
  Future<String> decrypt(String encryptedText);
}
