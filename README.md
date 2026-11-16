# WiFi Sonar iOS — перенос Android-клиента

Android-проект завершён и остаётся без изменений в [mgnkick/sonar](https://github.com/mgnkick/sonar). Этот репозиторий — отдельный нативный iPhone-клиент, максимально повторяющий существующий Android WiFi Sonar.

## Конфигурация
- Swift 5.9+, SwiftUI
- Minimum deployment target: iOS 16.0
- Bundle ID: com.mgnkick.wifisonar
- Русский и английский языки; светлая/тёмная темы
- Фирменный стиль Android: тёмная палитра, циановые/фиолетовые акценты, скруглённые карточки и нижняя навигация

## Изученная Android-основа
Проверены исходники `mgnkick/sonar`: MainActivity и навигация; DashboardScreen, SmartAuditScreen, DiagnosticScreen, SignalAnalysisScreen, ExperimentalHeatmapTab, ConnectionHistoryScreen; WifiRepository, SmartAuditEngine, NetworkDiagnosticRepository, ConnectionHistoryRepository, DiagnosticConsoleStore; WifiNetwork/AuditModels/DiagnosticModels; AppText RU/EN; Color/Theme.

Android-экранная структура: Сканер (Mesh), Смарт-Аудит, Диагностика, Спектр/Инфо, Карта, История. Также используются ?, About, локальный журнал, отчёты и резервная копия.

## Таблица соответствия Android → iOS

| Android-функция | Доступный способ на iOS | Ограничение iOS | Решение в интерфейсе |
|---|---|---|---|
| Сканирование соседних AP: SSID/BSSID/RSSI/частота/канал/ширина/security | NEHotspotNetwork.fetchCurrent при специальных условиях/entitlement; NWPathMonitor/getifaddrs для активного пути | Нет публичного API списка соседних точек и радио-параметров | Показать только доступную текущую сеть; соседние AP помечать недоступными |
| OUI/vendor, Mesh, roaming по BSSID | OUI lookup только при реально известном BSSID | BSSID часто скрыт; рандомизированный MAC не доказывает производителя | Не выдумывать производителя и топологию |
| Smart Audit: сигнал/перегрузка/защита | Текущие разрешённые сведения + DNS/TCP тесты | Нет соседних радиоизмерений и channel airtime | Частичный аудит; каждый недоступный критерий объяснён |
| ICMP ping | Network.framework даёт TCP connect latency | Нет надёжного общего публичного ICMP Echo API | Назвать результат TCP latency, не ICMP ping |
| Traceroute | Нет полноценного публичного hop-by-hop API | Нельзя достоверно реализовать TTL ICMP traceroute | Недоступно, с пояснением |
| Шлюз/DNS/интернет | NWPathMonitor, getifaddrs, getaddrinfo, NWConnection | Gateway/DNS servers могут быть скрыты; VPN меняет маршрут | Последовательные тесты и явное «неизвестно» |
| ECHO / поиск устройств | NWBrowser Bonjour browse | Только устройства/сервисы, объявляющие Bonjour; не полный список клиентов | Показ реальных Bonjour-сервисов и IP, если доступны |
| TCP port scanner | NWConnection к введённому адресу/порту | Локальная сеть требует разрешения; не делать массовое неограниченное сканирование | Ручная проверка выбранного хоста/портов и консоль |
| Wi-Fi spectrum | Публичного API Wi-Fi radio scan нет | Нельзя получить соседние каналы, ширину и RSSI | Экран сохраняется, но честно сообщает об ограничении |
| Текущая сеть | NWPathMonitor/getifaddrs; NEHotspotNetwork при условиях Apple | SSID/BSSID и radio values могут быть недоступны | Показывать доступные поля, остальные — «Недоступно на iOS» |
| История соединений/открытых сетей | Локальные события, наблюдаемые приложением | Нет системной истории и непрерывного фонового контроля | Только наблюдавшиеся события; без фиктивных записей |
| Геопозиция истории | CoreLocation When In Use | Только с разрешения, не гарантируется | Опциональные координаты и переход в Maps |
| Карта помещения | SwiftUI Canvas, PhotosPicker, MapKit | Нельзя автоматически собирать фоновые Wi-Fi замеры | Ручные точки/фигуры/подписи, router/satellite, zoom и экспорт |
| Отчёты/backup | Codable JSON versioned backup, PDFKit, fileImporter/exporter | Не включать секреты и пароли | Переносимый архив без Wi-Fi паролей, схема с миграцией |
| Фоновый мониторинг | BGTaskScheduler для ограниченных задач | Нет непрерывного Wi-Fi мониторинга; расписание не гарантировано | Best-effort обновление и предупреждение об ограничениях |
| Help/About/settings | SwiftUI локализация и @AppStorage | Все строки должны быть локализованы | RU/EN, темы и контекстные объяснения |

## Карта экранов Android
- **Сканер (Mesh):** группы SSID, BSSID nodes, RSSI, band/channel, security, vendor, topology/roaming hints.
- **Смарт-Аудит:** сигнал, канал, security, topology/latency и рекомендации.
- **Диагностика:** ping, traceroute, ECHO, port scan, потоковая консоль.
- **Спектр/Инфо:** соседние каналы и параметры активного подключения.
- **Карта:** план помещения, точки замеров, инструменты и экспорт.
- **История:** соединения и открытые сети, даты, координаты, export/backup.
- **Общее:** нижняя навигация, ?/About, RU/EN, light/dark.

## Архитектура iOS
`WiFiSonarApp.swift` — приложение и настройки; `RootView` — нижняя навигация; `SonarTheme` — палитра; `NetworkStatusService` — фактический путь/IP; `DiagnosticsService` — TCP/Bonjour; Feature views соответствуют Android-вкладкам. Следующие итерации должны выделить сервисы/модели по папкам, versioned history/backup, MapKit и полную локализацию.

## Требования к реализации
- Никаких приватных API, подмен shell-командами или фиктивных сетевых данных.
- Не сохранять Wi-Fi-пароли.
- Local Network и Location запрашивать только при первом использовании функции.
- Dynamic Type, VoiceOver, safe areas и разные размеры iPhone.
- Все видимые строки и консоль локализовать на русский/английский.
- История/настройки переживают обновления; backup имеет версию и миграции.

## Сборка
Требуются macOS и Xcode. Откройте `WiFiSonar.xcodeproj`, выберите iPhone Simulator или iPhone и выполните Product → Build. Bonjour, permissions и сетевые проверки нужно дополнительно проверить на физическом устройстве. GitHub API не заменяет Xcode/iOS SDK.
