/// Реквизиты исполнителя (ИП на НПД) для автозаполнения формы договора.
///
/// Раздел «Исполнитель» в договоре соответствует самому пользователю,
/// поэтому данные берутся из его профиля, а не вводятся вручную.
class ContractorProfile {
  final String fullName;
  final String inn;
  final String ogrnip;
  final String registrationAddress;
  final String bankName;
  final String bankAccount;
  final String bankBik;

  const ContractorProfile({
    required this.fullName,
    required this.inn,
    required this.ogrnip,
    required this.registrationAddress,
    required this.bankName,
    required this.bankAccount,
    required this.bankBik,
  });

  factory ContractorProfile.fromJson(Map<String, dynamic> json) {
    return ContractorProfile(
      fullName: json['fullName'] as String? ?? '',
      inn: json['inn'] as String? ?? '',
      ogrnip: json['ogrnip'] as String? ?? '',
      registrationAddress: json['registrationAddress'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      bankAccount: json['bankAccount'] as String? ?? '',
      bankBik: json['bankBik'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'inn': inn,
      'ogrnip': ogrnip,
      'registrationAddress': registrationAddress,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'bankBik': bankBik,
    };
  }

  /// Демонстрационный профиль для tracer-bullet фазы.
  static const demo = ContractorProfile(
    fullName: 'Иванов Иван Иванович',
    inn: '771234567890',
    ogrnip: '321770012345678',
    registrationAddress: 'г. Москва, ул. Строителей, д. 3, кв. 15',
    bankName: 'АО «Т-Банк»',
    bankAccount: '40817810000000001234',
    bankBik: '044525974',
  );
}
