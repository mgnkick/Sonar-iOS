# WiFi Sonar для iPhone

Отдельный нативный SwiftUI-клиент, построенный по завершённому Android-проекту [mgnkick/sonar](https://github.com/mgnkick/sonar). Android-репозиторий не изменяется.

> **Статус:** ранний рабочий каркас. Это ещё не функциональный паритет Android-версии и не готовый App Store релиз. Здесь уже есть Xcode-проект, экраны-наследники Android-навигации, реальные сетевые операции, локальная история и JSON backup. Остальные возможности перечислены отдельно как незавершённые.

## Конфигурация

- Swift 5 language mode, SwiftUI, Network.framework, NetworkExtension
- Minimum deployment target: **iOS 16.0**
- Bundle ID: `com.mgnkick.wifisonar`
- Display name: **WiFi Sonar**
- Русский и английский: `Localizable.strings` и `InfoPlist.strings`
- Светлая/тёмная тема, системные размеры шрифта для основного текста, нижняя навигация и фирменные тёмные карточки с циановыми/фиолетовыми акцентами

## Изученная Android-основа

Проверены исходники `mgnkick/sonar`:

- Навигация и приложение: `MainActivity.kt`
- Экраны: `DashboardScreen.kt`, `SmartAuditScreen.kt`, `DiagnosticScreen.kt`, `SignalAnalysisScreen.kt`, `ExperimentalHeatmapTab.kt`, `ConnectionHistoryScreen.kt`
- Сетевые сервисы: `WifiRepository.kt`, `NetworkDiagnosticRepository.kt`, `SmartAuditEngine.kt`, `WifiTopologyAnalyzer.kt`, `ChannelInterferenceAnalyzer.kt`
- История и данные: `ConnectionHistoryRepository.kt`, `OpenNetworkLogRepository.kt`, `DiagnosticConsoleStore.kt`, `AppDataBackup.kt`, модели Wi-Fi/audit/diagnostics
- Визуальный стиль и локализация: `Color.kt`, `Theme.kt`, `AppText.kt`

## Таблица переноса Android → iOS

| Android-функция | Реальный механизм iOS | Ограничение платформы | Решение WiFi Sonar |
|---|---|---|---|
| Сканирование соседних точек доступа | Общего публичного API Wi-Fi scan нет | Нельзя получить список соседних AP, их SSID/BSSID/RSSI/частоты/каналы/ширины | Раздел «Соседние сети» объясняет ограничение; не генерирует фиктивные данные |
| Параметры текущей сети | `NEHotspotNetwork.fetchCurrent()` | Требуется Access Wi-Fi Information entitlement и одно из условий Apple; возможен nil | Кнопка запрашивает SSID/BSSID/security type. Не полученные поля остаются недоступными |
| IP и состояние сетевого пути | `NWPathMonitor`, `getifaddrs` | Не раскрывают радио-параметры Wi-Fi | Реальный статус пути и IPv4 на интерфейсе Wi-Fi |
| OUI/vendor, Mesh, 802.11k/r/v | Только если исходные данные реально доступны | Без BSSID и радио-данных достоверный анализ невозможен | Не подменяется эвристикой по одному SSID |
| Smart Audit | Сейчас только обзор доступности данных | Нет signal/channel/airtime/AP security facts | Экран сохранён; недоступные метрики явно перечислены. Расчётный аудит — будущая работа |
| ICMP ping | `Network.framework` TCP connection timing | TCP latency не эквивалентен ICMP RTT | Приложение называет проверку TCP, не «ping» |
| Traceroute | Нет общего публичного API hop-by-hop traceroute для обычного приложения | ICMP TTL/маршрут нельзя честно повторить | Выведено пояснение об ограничении |
| Gateway/DNS/Internet check | NWPath, DNS resolution, TCP probes | Точный gateway и DNS server list могут быть скрыты; полноценная последовательность пока не реализована | Следующий этап диагностики |
| ЭХО / поиск устройств | `NWBrowser` Bonjour browsing | Видны только сервисы, которые устройства объявили через Bonjour; это не полный список клиентов и не ARP/ICMP sweep | Сейчас ищутся HTTP Bonjour-сервисы. Не найденные устройства не считаются отсутствующими |
| TCP port scanner | `NWConnection` к заданному IPv4 и портам | Local Network permission, возможная фильтрация, только выбранный private IPv4 диапазон в текущей реализации | Проверка до 32 портов на одном private IPv4, результаты в консоли |
| Wi-Fi Spectrum | Нет публичного radio scan API | Нельзя построить канал/RSSI/ширину соседних AP | Экран сохранён с объяснением, но не рисует выдуманный спектр |
| История подключений | `NWPathMonitor` callbacks во время работы приложения | iOS не отдаёт системную историю; фоновые события не гарантированы | Локально фиксируются только наблюдённые смены сетевого пути |
| История открытых Wi-Fi сетей | Нет разрешённого API сканирования соседних точек | Открытые AP нельзя обнаружить через общую сеть Wi-Fi API | В iOS-проекте не реализована |
| Карта обследования | SwiftUI canvas + PhotosUI | Нет автоматических Wi-Fi замеров в фоне | Ручной холст с фото/планом-подложкой, ручными точками и router/satellite markers, панорамированием/масштабом; схема и фото сохраняются локально |
| Геопривязка, полноценные фигуры, экспорт изображения | CoreLocation, Canvas, MapKit, ImageRenderer | Требуются отдельные сценарии разрешения/экспорта | Пока не реализованы; текущие метки не являются полноценным редактором фигур |
| PDF-отчёты | PDFKit / UIGraphicsPDFRenderer | Ещё не перенесено | Следующий этап |
| JSON backup | Codable + fileImporter/ShareLink | Текущая схема содержит историю событий, не полный набор Android-данных | Экспорт и импорт версии 1, принимается legacy-массив событий |
| Фоновый мониторинг | BGTaskScheduler | Не гарантирует непрерывное выполнение или регулярное сканирование Wi-Fi | Не включён; не обещается непрерывный мониторинг |
| RU/EN, темы, Help/About | SwiftUI localization, AppStorage | Нужно дополнительно пройти все экраны и VoiceOver | Базовые строки переведены, язык/тема переключаются в настройках |

## Что уже реализовано в iOS-каркасе

- Отдельный Xcode project и shared scheme `WiFiSonar`.
- Шесть разделов: Scanner, Smart Audit, Diagnostics, Spectrum, Survey Map, History.
- Нижняя навигация, карточки, фирменная палитра, светлая/тёмная тема, RU/EN.
- Текущий сетевой путь и IP-адрес Wi-Fi интерфейса, где он доступен.
- Запрос текущих SSID/BSSID/security через Apple API (зависит от entitlement и системных условий).
- TCP-проверки списка портов на private IPv4 адресе; журнал результатов.
- Bonjour HTTP service discovery с запросом Local Network permission при первом запуске поиска.
- Ручные точки на карте замеров, router/satellite обозначения, pan/zoom.
- Локальная запись изменений сетевого состояния, JSON экспорт/импорт, миграция раннего формата событий.
- CI workflow для сборки iOS Simulator на macOS.

## Что ещё не перенесено

- Полный Smart Audit и расчёт рекомендации на реальных Wi-Fi radio metrics.
- Соседние Wi-Fi сети, spectrum, channel overlap и vendor detection.
- Полноценные ICMP ping, traceroute, gateway/DNS/Internet sequence.
- Полный ECHO subnet discovery с IP-адресами/ARP.
- Открытые AP history.
- Геопривязка замеров, переход к координатам Apple Maps, полноценный редактор линий/фигур/текста.
- Геометки и переход к координатам в Apple Maps.
- Экспорт изображения карты и PDF-отчёты.
- Полный перенос данных Android backup.
- BGTaskScheduler background monitoring.
- Полный тест VoiceOver, Dynamic Type и ручные UI tests на разных iPhone.

## Apple Wi-Fi entitlement

Метод `NEHotspotNetwork.fetchCurrent()` возвращает только данные о **текущей** сети (SSID, BSSID и security type), не RSSI/частоту/канал. Он может вернуть nil без entitlement `com.apple.developer.networking.wifi-info` и выполнения одного из системных условий (например, precise Location authorization, конфигурация сети приложением или активные VPN/DNS settings). В текущем Xcode-проекте entitlement намеренно не вшит, чтобы не создавать недействительную подпись. Для проверки реального получения данных владелец должен получить/подключить разрешённый Apple entitlement в Signing & Capabilities и provisioning profile.

Bonjour использует `NSLocalNetworkUsageDescription` и декларацию `NSBonjourServices` в Info.plist; системный запрос появляется при фактическом запуске обнаружения.

## Сборка и запуск

1. Установить Xcode на macOS.
2. Клонировать `https://github.com/mgnkick/Sonar-iOS.git`.
3. Открыть `WiFiSonar.xcodeproj`.
4. Выбрать схему `WiFiSonar` и iPhone Simulator либо подключённый iPhone.
5. Выполнить **Product → Build**, затем **Product → Run**.

Минимальная версия — iOS 16.0. CI выполняет симуляторную сборку без подписи. Для реального iPhone потребуется выбрать Team и настроить signing. Локальная сеть и Bonjour должны тестироваться на физическом устройстве; симулятор не заменяет проверку разрешений и сетевой среды.

## Приватность

- Пароли Wi-Fi не считываются и не сохраняются.
- История и резервная копия локальные; backup не содержит паролей.
- Local Network доступ запрашивается только при запуске Bonjour-поиска.
- Геопозиция в текущем каркасе ещё не запрашивается.
- Недоступные системные данные не заменяются догадками.
