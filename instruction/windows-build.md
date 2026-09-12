# Сборка Windows-версии NPD Shield

Инструкция по самостоятельной сборке десктопного приложения под Windows.

**Проверено на:** Flutter 3.44.8 (stable) / Dart 3.13.2, Windows x64.
**Результат сборки:** `build\windows\x64\runner\Release\npd_shield.exe`, размер папки-бандла ~37,4 МБ.

> ⚠️ **Важно про версию Flutter.** В `pubspec.yaml` указано `sdk: ^3.13.2`, то есть нужен **Dart ≥ 3.13.2**. Публичные релизы Flutter соотносятся с Dart так:
>
> | Flutter | Dart | Подходит? |
> |---|---|---|
> | 3.44.8 | 3.12.2 | ❌ `version solving failed` |
> | **3.47.2** | **3.13.2** | ✅ совпадает с версией Dart на машине разработчика |
> | 3.47.4 | 3.13.3 | ✅ последняя стабильная на момент написания |
>
> На машине, где собирался проект, установлен Flutter, который сообщает себя как 3.44.8, но содержит Dart 3.13.2 — такого публичного релиза **не существует** (framework от 23.07.2026, а Dart SDK от 26.08.2026). Если поставить публичный Flutter 3.44.8, `flutter pub get` упадёт с ошибкой `Because npd_shield requires SDK version ^3.13.2, version solving failed`. **Для воспроизводимой сборки из публичных релизов используйте Flutter 3.47.2 или новее.**

---

## 1. Кратко (TL;DR)

```powershell
cd "D:\Dev\NPD Shield\npd_shield"
flutter pub get
flutter build windows --release
```

Готовое приложение — в `build\windows\x64\runner\Release\`. Запускать нужно `npd_shield.exe` **из этой папки**, вместе с лежащими рядом DLL и папкой `data`.

---

## 2. Что должно быть установлено

| Компонент | Требование | Зачем |
|---|---|---|
| Windows | 10 (1809+) или 11, x64 | Целевая платформа |
| Flutter SDK | 3.47.2 stable или новее (канал stable) | Сборочный тулчейн; версия ниже 3.47.2 не подойдёт — см. предупреждение выше |
| Dart SDK | 3.13.2 — идёт в комплекте с Flutter | Компиляция |
| Visual Studio 2022 | **Обязательно** с рабочей нагрузкой «Разработка классических приложений на C++» (Desktop development with C++) | Компилятор MSVC, CMake-сборка нативного runner'а |
| Windows SDK | 10.0.17763.0 или новее (ставится вместе с рабочей нагрузкой VS) | Заголовки и библиотеки Win32 |
| Режим разработчика | Включён: «Параметры → Система → Для разработчиков → Режим разработчика» | Flutter создаёт симлинки при подключении плагинов |
| Свободное место | ~10 ГБ | Кэш артефактов движка + артефакты сборки |

Без рабочей нагрузки C++ сборка падает с ошибкой `Unable to find suitable Visual Studio toolchain`.

---

## 3. Проверка окружения

```powershell
flutter --version
flutter doctor -v
```

В выводе `flutter doctor` должна быть строка вида:

```
[√] Visual Studio - develop Windows apps (Visual Studio Community 2022 17.x)
```

Если напротив Visual Studio стоит `[X]`, установите рабочую нагрузку C++ через Visual Studio Installer и повторите проверку.

Дополнительно можно явно включить десктопную платформу (для свежих версий Flutter она включена по умолчанию):

```powershell
flutter config --enable-windows-desktop
```

---

## 4. Пошаговая сборка

### Шаг 1. Перейти в корень проекта

```powershell
cd "D:\Dev\NPD Shield\npd_shield"
```

> Проект лежит в пути с пробелом (`NPD Shield`). Это допустимо, но если возникают странные ошибки CMake/MSBuild, попробуйте скопировать проект в путь без пробелов и кириллицы, например `D:\build\npd_shield`.

### Шаг 2. Скачать зависимости

```powershell
flutter pub get
```

Что должно произойти: пакеты `isar`, `pdf`, `printing`, `fl_chart`, `dynamic_color`, `flutter_secure_storage` и остальные разрешаются и попадают в pub-cache.

### Шаг 3 (только при изменении моделей БД). Перегенерировать код Isar

Файлы `lib/data/models/*.g.dart` уже лежат в репозитории, поэтому на чистом клоне этот шаг **не нужен**. Выполняйте его, только если правили `@collection`-классы (`transaction.dart`, `contract_draft.dart`, `contract_template.dart`):

```powershell
dart run build_runner build --delete-conflicting-outputs
```

### Шаг 4. Собрать release-версию

```powershell
flutter build windows --release
```

- Первая сборка занимает до нескольких минут (скачиваются артефакты движка, собирается C++ runner). В проверенной сборке — около 130 секунд.
- Повторные сборки заметно быстрее.
- Ожидаемый финальный вывод:

```
Building Windows application...
√ Built build\windows\x64\runner\Release\npd_shield.exe
```

Флаги, которые могут пригодиться:

| Флаг | Когда нужен |
|---|---|
| `--debug` | Сборка debug-варианта (без оптимизаций, для отладки) |
| `--no-tree-shake-icons` | Если понадобились динамически подставляемые иконки (по умолчанию Flutter их вырезает) |
| `-v` | Подробный лог — только для диагностики проблем сборки |

---

## 5. Запуск собранного приложения

```powershell
.\build\windows\x64\runner\Release\npd_shield.exe
```

Или двойным щелчком по `npd_shield.exe` в проводнике.

Для запуска в режиме разработки (с hot reload) вместо сборки релиза:

```powershell
flutter run -d windows
```

---

## 6. Состав готового дистрибутива

Папка `build\windows\x64\runner\Release\` — это и есть дистрибутив целиком. В проверенной сборке там:

```
npd_shield.exe                            — исполняемый файл приложения
flutter_windows.dll                       — движок Flutter
isar.dll                                  — нативная библиотека Isar (локальная БД)
isar_flutter_libs_plugin.dll              — плагин Isar
pdfium.dll                                — движок рендеринга PDF
printing_plugin.dll                       — печать и шаринг PDF
dynamic_color_plugin.dll                  — Dynamic Color (Material You)
flutter_secure_storage_windows_plugin.dll — защищённое хранилище ключей шифрования
dartjni.dll                               — JNI-мост для плагинов
data\
  app.so                                  — скомпилированный Dart-код (AOT)
  icudtl.dat                              — данные интернационализации
  flutter_assets\                         — ресурсы приложения:
      assets\templates\*.txt              — 6 встроенных шаблонов договоров
      assets\fonts\Roboto-*.ttf           — шрифты для PDF (кириллица)
      AssetManifest.bin, FontManifest.json, NOTICES и др.
```

**Важно:** копировать один `npd_shield.exe` нельзя — приложение не запустится. Передавайте папку `Release` целиком (например, заархивировав её в ZIP).

На целевой машине пользователя должен быть установлен **Microsoft Visual C++ Redistributable 2015–2022 (x64)** — обычно он уже есть в системе, но на чистой Windows его может не быть.

### Где приложение хранит данные

| Данные | Расположение |
|---|---|
| База Isar (транзакции, шаблоны, черновики) | папка «Документы» пользователя (`%USERPROFILE%\Documents\`) |
| Профиль ИП | SharedPreferences (реестр/AppData) |
| Ключ шифрования AES-256 и IV | Windows Credential Manager (через `flutter_secure_storage`) |

Ключ шифрования привязан к учётной записи Windows: перенос папки с базой на другую машину/пользователя сделает зашифрованные поля (`clientName`, `clientInn`) нечитаемыми.

---

## 7. Сборка установщика (опционально)

ZIP-архива достаточно для внутреннего использования. Если нужен установщик:

- **Inno Setup / NSIS** — упаковать содержимое `Release\` в установщик, добавив проверку/установку VC++ Redistributable.
- **MSIX** — через пакет `msix` (добавляется в `dev_dependencies`), команда `dart run msix:create`. Требует подписи сертификатом для установки без предупреждений.
- **Microsoft Store** — упаковка MSIX с подписью из Partner Center.

---

## 8. Полезные команды

```powershell
flutter clean                            # очистить артефакты сборки
flutter pub get                          # восстановить зависимости
flutter analyze                          # статический анализ
flutter test                             # прогнать тесты
flutter build windows --release          # release-сборка
flutter run -d windows                   # запуск в режиме отладки
```

> Для `flutter test` на Windows в корне проекта нужен файл `isar.dll` (он лежит в репозитории локально и добавлен в `.gitignore`). Если его нет — скопируйте `isar.dll` из `build\windows\x64\runner\Release\` в корень проекта, иначе тесты, работающие с Isar, не найдут нативную библиотеку.

---

## 9. Типичные проблемы

| Симптом | Причина | Решение |
|---|---|---|
| `Because npd_shield requires SDK version ^3.13.2, version solving failed` | Версия Flutter ниже 3.47.2, её Dart старше 3.13.2 | Обновить Flutter до 3.47.2 или новее (`flutter upgrade` либо `flutter version 3.47.2`); подробности — в предупреждении в начале документа |
| `Unable to find suitable Visual Studio toolchain` | Не установлена рабочая нагрузка C++ | Visual Studio Installer → изменить → «Разработка классических приложений на C++» |
| `Building with plugins requires symlink support` | Выключен режим разработчика | Включить «Режим разработчика» в параметрах Windows |
| Сборка зависает и **не выводит ни одной строки** | Нет прав на запись в кэш Flutter SDK (`<flutter>\bin\cache`) или в pub-cache (`%LOCALAPPDATA%\Pub\Cache`) | Запустить терминал с достаточными правами; при работе из песочницы/ограниченного окружения — разрешить запись в эти каталоги. Именно эта ситуация наблюдалась при сборке из ограниченной среды |
| `Target dartjni failed` / ошибки плагинов | Битые промежуточные артефакты | `flutter clean`, затем `flutter pub get` и повторная сборка |
| Приложение показывает «Не удалось инициализировать базу данных» | Нет прав на запись в «Документы», повреждена БД или уже запущен второй экземпляр | Проверить права на папку «Документы», закрыть другие экземпляры приложения, при необходимости удалить файл БД |
| Кириллица в PDF «квадратиками» | Потеряны шрифты Roboto | Убедиться, что `assets/fonts/Roboto-Regular.ttf` и `Roboto-Bold.ttf` на месте и объявлены в `pubspec.yaml` |
| Долгая сборка, антивирус грузит диск | Сканирование `build\` и кэша SDK | Добавить в исключения антивируса папки проекта и Flutter SDK |
| `Path too long` при сборке | Глубокий путь к проекту | Сократить путь или включить поддержку длинных путей в Windows |

---

## 10. Зафиксированный результат проверочной сборки

| Параметр | Значение |
|---|---|
| Flutter | 3.44.8 stable, локальная сборка SDK (framework `058e0af2c2b` от 23.07.2026, engine `a804b26164` от 26.08.2026) — публичного релиза с такой комбинацией нет, см. предупреждение выше |
| Dart | 3.13.2 |
| Команда | `flutter build windows --release` |
| Время сборки | ~130 с |
| Артефакт | `build\windows\x64\runner\Release\npd_shield.exe` (92 КБ) |
| Версия в метаданных exe | 1.0.0+1 |
| AOT-код | `data\app.so` (8,5 МБ) |
| Размер дистрибутива | ~37,4 МБ |
| Встроенные шаблоны | 6 шт. (2 IT, 2 логистики, 2 универсальных) |
