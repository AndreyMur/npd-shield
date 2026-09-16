import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npd_shield/domain/profile/contractor_profile.dart';
import 'package:npd_shield/presentation/settings/profile_edit_screen.dart';

import 'helpers/fake_contract_repositories.dart';

void main() {
  late FakeContractorProfileRepository profile;

  setUp(() => profile = FakeContractorProfileRepository());

  Future<void> pumpEditor(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileEditScreen(profileRepository: profile),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('загружает сохранённый профиль в поля', (tester) async {
    profile.profile = const ContractorProfile(
      fullName: 'Петров Пётр Петрович',
      inn: '771234567890',
      ogrnip: '321770012345678',
      registrationAddress: 'г. Санкт-Петербург',
      bankName: 'АО «Т-Банк»',
      bankAccount: '40817810000000001234',
      bankBik: '044525974',
    );

    await pumpEditor(tester);

    expect(
      find.widgetWithText(TextFormField, 'Петров Пётр Петрович'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, '771234567890'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, '321770012345678'),
      findsOneWidget,
    );
  });

  testWidgets('сохраняет изменённый профиль и закрывает экран', (tester) async {
    await pumpEditor(tester);

    await tester.enterText(
      find.byKey(const Key('profile_full_name')),
      'Сидоров Сидор Сидорович',
    );
    await tester.enterText(find.byKey(const Key('profile_inn')), '771234567890');
    await tester.enterText(
      find.byKey(const Key('profile_ogrnip')),
      '321770012345678',
    );

    await tester.tap(find.byKey(const Key('profile_save')));
    await tester.pumpAndSettle();

    expect(profile.profile?.fullName, 'Сидоров Сидор Сидорович');
    expect(profile.profile?.inn, '771234567890');
    expect(profile.profile?.ogrnip, '321770012345678');
  });

  testWidgets('некорректный ИНН не сохраняется', (tester) async {
    await pumpEditor(tester);

    await tester.enterText(find.byKey(const Key('profile_inn')), '123');
    await tester.tap(find.byKey(const Key('profile_save')));
    await tester.pumpAndSettle();

    expect(find.text('Введите 10 или 12 цифр'), findsOneWidget);
    expect(profile.profile, isNull);
  });

  testWidgets('очистка всех полей удаляет сохранённый профиль', (tester) async {
    profile.profile = const ContractorProfile(
      fullName: 'Иванов Иван Иванович',
      inn: '',
      ogrnip: '',
      registrationAddress: '',
      bankName: '',
      bankAccount: '',
      bankBik: '',
    );

    await pumpEditor(tester);
    await tester.enterText(find.byKey(const Key('profile_full_name')), '');
    await tester.tap(find.byKey(const Key('profile_save')));
    await tester.pumpAndSettle();

    expect(profile.profile, isNull);
  });
}
