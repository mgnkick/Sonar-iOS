import SwiftUI
import Network
import NetworkExtension
import SystemConfiguration
import Darwin
import UIKit
import UniformTypeIdentifiers

@main
struct WiFiSonarApp: App {
    @AppStorage("appLanguage") private var appLanguage = "ru"
    @AppStorage("darkTheme") private var darkTheme = true
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.locale, Locale(identifier: appLanguage))
                .preferredColorScheme(darkTheme ? .dark : .light)
        }
    }
}

enum SonarTab: String, CaseIterable, Identifiable {
    case scanner, audit, diagnostics, spectrum, map, history
    var id: String { rawValue }
    var title: LocalizedStringKey {
        switch self {
        case .scanner: "Сканер"
        case .audit: "Аудит"
        case .diagnostics: "Диагностика"
        case .spectrum: "Спектр"
        case .map: "Карта"
        case .history: "История"
        }
    }
    var symbol: String {
        switch self {
        case .scanner: "wifi"
        case .audit: "checkmark.shield"
        case .diagnostics: "waveform.path"
        case .spectrum: "chart.bar.xaxis"
        case .map: "map"
        case .history: "clock.arrow.circlepath"
        }
    }
}

struct RootView: View {
    @State private var selection: SonarTab = .scanner
    @State private var showAbout = false
    @State private var helpMode = false
    @State private var showSettings = false
    @AppStorage("appLanguage") private var appLanguage = "ru"
    @AppStorage("darkTheme") private var darkTheme = true
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("WiFi Sonar").font(.title2.weight(.bold))
                    Text(selection.title).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { helpMode.toggle() } label: {
                    Image(systemName: "questionmark.circle").font(.title3)
                        .foregroundStyle(helpMode ? SonarTheme.cyan : .secondary)
                }.accessibilityLabel(Text("Режим подсказок"))
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape").font(.title3)
                }.accessibilityLabel(Text("Настройки"))
                Button { showAbout = true } label: {
                    Image(systemName: "info.circle").font(.title3)
                }.accessibilityLabel(Text("О программе"))
            }.padding(.horizontal, 16).padding(.vertical, 12)

            if helpMode {
                Text("Подсказки: нажмите на ? ещё раз, чтобы скрыть режим подсказок.")
                    .font(.caption).foregroundStyle(SonarTheme.cyan)
                    .padding(.horizontal, 16).padding(.bottom, 8)
            }

            Group {
                switch selection {
                case .scanner: ScannerView()
                case .audit: AuditView()
                case .diagnostics: DiagnosticsView()
                case .spectrum: SpectrumView()
                case .map: SurveyMapView()
                case .history: HistoryView()
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 0) {
                ForEach(SonarTab.allCases) { tab in
                    Button { selection = tab } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tab.symbol).font(.system(size: 17, weight: .semibold))
                            Text(tab.title).font(.system(size: 10, weight: .medium))
                                .lineLimit(1).minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(selection == tab ? SonarTheme.cyan : Color.secondary)
                        .frame(maxWidth: .infinity).padding(.vertical, 9)
                        .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                     .accessibilityAddTraits(selection == tab ? .isSelected : [])
                }
            }.padding(.horizontal, 4).background(.ultraThinMaterial)
             .overlay(alignment: .top) { Rectangle().fill(SonarTheme.border).frame(height: 1) }
        }
        .background(SonarTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showAbout) { AboutView() }
        .sheet(isPresented: $showSettings) {
            SettingsView(appLanguage: $appLanguage, darkTheme: $darkTheme)
        }
    }
}

enum SonarTheme {
    static let background = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 5/255, green: 6/255, blue: 8/255, alpha: 1)
            : UIColor(red: 242/255, green: 247/255, blue: 251/255, alpha: 1)
    })
    static let surface = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 13/255, green: 15/255, blue: 18/255, alpha: 1)
            : UIColor(red: 244/255, green: 245/255, blue: 246/255, alpha: 1)
    })
    static let surfaceVariant = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 25/255, green: 28/255, blue: 33/255, alpha: 1)
            : UIColor(red: 232/255, green: 234/255, blue: 237/255, alpha: 1)
    })
    static let cyan = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 84/255, green: 244/255, blue: 1, alpha: 1)
            : UIColor(red: 0/255, green: 111/255, blue: 131/255, alpha: 1)
    })
    static let violet = Color(red: 155/255, green: 140/255, blue: 1)
    static let magenta = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 79/255, blue: 216/255, alpha: 1)
            : UIColor(red: 158/255, green: 40/255, blue: 111/255, alpha: 1)
    })
    static let green = Color(red: 100/255, green: 247/255, blue: 176/255)
    static let border = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 57/255, green: 49/255, blue: 95/255, alpha: 1)
            : UIColor(red: 188/255, green: 197/255, blue: 206/255, alpha: 1)
    })
}

struct SonarCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(15).frame(maxWidth: .infinity, alignment: .leading)
            .background(SonarTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(SonarTheme.border.opacity(0.8), lineWidth: 1))
    }
}

struct ScreenScroll<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 13) {
                Text(title).font(.title2.weight(.bold))
                content
            }.padding(15)
        }
    }
}

struct ScannerView: View {
    @StateObject private var network = NetworkStatusService()
    var body: some View {
        ScreenScroll(title: "Сканер (Mesh)") {
            SonarCard {
                Label("Текущее подключение", systemImage: "wifi")
                    .font(.headline).foregroundStyle(SonarTheme.cyan)
                HStack { Text(network.isWiFi ? String(localized: "Wi-Fi") : String(localized: "Сетевой путь")); Spacer(); Text(network.statusText).foregroundStyle(.secondary) }
                if let ip = network.ipAddress { infoRow("Локальный IP", ip) }
                else { unavailableRow("Локальный IP") }
                infoRow("SSID", network.currentSSID ?? String(localized: "Недоступно"))
                infoRow("BSSID", network.currentBSSID ?? String(localized: "Недоступно"))
                infoRow("Защита Wi-Fi", network.securityType ?? String(localized: "Недоступно"))
                if let note = network.currentInfoNote {
                    Text(note).font(.caption).foregroundStyle(.secondary)
                }
                Button("Получить параметры текущей сети") {
                    network.readCurrentWiFiInfo()
                }.buttonStyle(.bordered)
                unavailableRow("RSSI / уровень сигнала")
                unavailableRow("Частота / канал / ширина")
            }
            SonarCard {
                Label("Соседние сети", systemImage: "antenna.radiowaves.left.and.right").font(.headline)
                Text("iOS не предоставляет обычным приложениям публичный API сканирования соседних точек доступа. WiFi Sonar не показывает вымышленные сети.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("Недоступно на iOS").font(.caption.weight(.semibold)).foregroundStyle(SonarTheme.magenta)
            }
            SonarCard {
                Label("Обновление состояния", systemImage: "arrow.clockwise").font(.headline)
                Button("Обновить") { network.refreshInterface() }.buttonStyle(.borderedProminent).tint(SonarTheme.cyan)
            }
        }.onAppear { network.start() }
    }
    private func infoRow(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack { Text(title); Spacer(); Text(value).foregroundStyle(.secondary).textSelection(.enabled) }.font(.subheadline)
    }
    private func unavailableRow(_ title: LocalizedStringKey) -> some View {
        HStack { Text(title); Spacer(); Text(String(localized: "Недоступно")).foregroundStyle(.secondary) }.font(.subheadline)
    }
}

struct AuditView: View {
    @StateObject private var network = NetworkStatusService()
    var body: some View {
        ScreenScroll(title: "Смарт-Аудит") {
            SonarCard {
                Label("Предварительная оценка", systemImage: "checkmark.shield").font(.headline).foregroundStyle(SonarTheme.cyan)
                Text(network.isWiFi ? "Wi-Fi-путь обнаружен. Для полноценной оценки выполните сетевые проверки." : "Активный Wi-Fi-путь не подтверждён.")
                    .font(.subheadline)
                Divider()
                auditItem("Сила сигнала", "Недоступно на iOS")
                auditItem("Перегруженность каналов", "Недоступно на iOS")
                auditItem("Безопасность точки доступа", "Недоступно на iOS")
                auditItem("DNS / Интернет", "Проверяется во вкладке Диагностика")
            }
            SonarCard {
                Text("Почему аудит частичный?").font(.headline)
                Text("iOS не раскрывает соседние сети и параметры радиоэфира обычным приложениям. Оценки помех, канала и Mesh-топологии без этих данных были бы недостоверными.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }.onAppear { network.start() }
    }
    private func auditItem(_ name: LocalizedStringKey, _ result: LocalizedStringKey) -> some View {
        HStack(alignment: .top) { Text(name); Spacer(minLength: 8); Text(result).foregroundStyle(.secondary).multilineTextAlignment(.trailing) }
            .font(.subheadline)
    }
}

struct DiagnosticsView: View {
    @StateObject private var diagnostics = DiagnosticsService()
    @State private var host = "192.168.1.1"
    @State private var ports = "22,80,443,8080"
    var body: some View {
        ScreenScroll(title: "Диагностика") {
            SonarCard {
                Text("TCP-проверка доступности").font(.headline)
                TextField("Адрес или имя узла", text: $host).textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(.roundedBorder)
                TextField("Порты через запятую", text: $ports).keyboardType(.numbersAndPunctuation).textFieldStyle(.roundedBorder)
                Button { diagnostics.scanTCP(host: host, ports: ports) } label: {
                    Label("Проверить TCP-порты", systemImage: "play.fill")
                }.buttonStyle(.borderedProminent).tint(SonarTheme.cyan)
                Text("Проверяются только введённые порты выбранного IPv4-адреса. Задержка TCP не является ICMP ping.").font(.caption).foregroundStyle(.secondary)
            }
            SonarCard {
                Text("Локальная сеть (Bonjour)").font(.headline)
                Button("Найти объявленные устройства") { diagnostics.startBonjourDiscovery() }.buttonStyle(.bordered)
                Text("iOS обнаруживает только совместимые Bonjour-сервисы. Это не полный список устройств роутера.")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(diagnostics.services, id: \.self) { Text($0).font(.caption.monospaced()) }
            }
            SonarCard {
                Text("Консоль результатов").font(.headline)
                if diagnostics.logs.isEmpty { Text("Результаты появятся после запуска проверки.").foregroundStyle(.secondary).font(.caption) }
                ForEach(Array(diagnostics.logs.enumerated()), id: \.offset) { item in
                    Text(item.element).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            SonarCard {
                Text("Traceroute / ICMP ping").font(.headline)
                Text("Полноценный ICMP ping и hop-by-hop traceroute не реализованы: публичные API iOS не дают надёжного общего доступа к этим операциям.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

struct SpectrumView: View {
    var body: some View {
        ScreenScroll(title: "Спектр / Информация") {
            SonarCard {
                Label("Радиоэфир Wi-Fi", systemImage: "chart.bar.xaxis").font(.headline)
                Text("iOS не предоставляет сторонним приложениям список соседних точек доступа, их каналы, ширину канала или RSSI. Построение спектра без этих данных было бы фиктивным.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("Анализ соседних каналов недоступен на iOS.").font(.caption.weight(.semibold)).foregroundStyle(SonarTheme.magenta)
            }
            SonarCard {
                Text("Текущая сеть").font(.headline)
                Text("Параметры, скрытые системой или недоступные без специальных разрешений Apple, обозначаются как недоступные.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

struct SurveyMapView: View {
    @State private var points: [SurveyPoint] = []
    @State private var label = ""
    @State private var selectedTool = "Точка"
    @State private var zoom: CGFloat = 1
    @State private var pan = CGSize.zero
    private let tools = ["Точка", "Роутер", "Сателлит", "Линия", "Фигура", "Текст"]
    var body: some View {
        ScreenScroll(title: "Карта замеров") {
            SonarCard {
                Picker("Инструмент", selection: $selectedTool) {
                    ForEach(tools, id: \.self) { Text(LocalizedStringKey($0)).tag($0) }
                }.pickerStyle(.menu)
                TextField("Подпись точки", text: $label).textFieldStyle(.roundedBorder)
                HStack {
                    Button("Добавить точку") {
                        points.append(SurveyPoint(title: label.isEmpty ? "Замер \(points.count + 1)" : label, x: 0.5, y: 0.5, kind: selectedTool))
                        label = ""
                    }.buttonStyle(.borderedProminent).tint(SonarTheme.cyan)
                    Button("Очистить") { points.removeAll() }.buttonStyle(.bordered)
                }
                GeometryReader { proxy in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(SonarTheme.surfaceVariant)
                        Path { path in
                            stride(from: 0.0, through: 1.0, by: 0.1).forEach { f in
                                let offset = CGFloat(f)
                                path.move(to: CGPoint(x: proxy.size.width * offset, y: 0))
                                path.addLine(to: CGPoint(x: proxy.size.width * offset, y: proxy.size.height))
                                path.move(to: CGPoint(x: 0, y: proxy.size.height * offset))
                                path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height * offset))
                            }
                        }.stroke(SonarTheme.border, lineWidth: 0.5)
                        ForEach(points) { point in
                            VStack(spacing: 2) {
                                Image(systemName: point.kind == "Роутер" ? "wifi.router" : point.kind == "Сателлит" ? "dot.radiowaves.left.and.right" : "mappin.circle.fill")
                                    .foregroundStyle(SonarTheme.cyan)
                                Text(point.title).font(.system(size: 9)).lineLimit(1)
                            }.position(x: proxy.size.width * point.x, y: proxy.size.height * point.y)
                        }
                    }
                    .scaleEffect(zoom)
                    .offset(pan)
                    .simultaneousGesture(MagnificationGesture().onChanged { value in
                        zoom = min(max(value, 0.65), 2.5)
                    })
                    .simultaneousGesture(DragGesture(minimumDistance: 10).onChanged { value in
                        pan = value.translation
                    })
                    .simultaneousGesture(SpatialTapGesture().onEnded { value in
                        let point = value.location
                        points.append(SurveyPoint(title: label.isEmpty ? "Замер \(points.count + 1)" : label,
                                                  x: min(max(point.x / proxy.size.width, 0), 1),
                                                  y: min(max(point.y / proxy.size.height, 0), 1),
                                                  kind: selectedTool))
                        label = ""
                    })
                }.frame(height: 320).clipped()
                Text("Это ручная схема помещения, не автоматическая тепловая карта.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct HistoryView: View {
    @State private var events = HistoryStore.load()
    @AppStorage("appLanguage") private var appLanguage = "ru"
    @State private var showImporter = false
    @State private var importMessage: String?
    var body: some View {
        ScreenScroll(title: "История") {
            SonarCard {
                Text("Наблюдаемые события").font(.headline)
                Text("iOS не предоставляет системную историю Wi-Fi-подключений. Здесь будут отображаться только события, которые приложение реально наблюдало во время работы.")
                    .font(.subheadline).foregroundStyle(.secondary)
                HStack {
                    ShareLink(item: HistoryStore.exportJSON(), preview: SharePreview("WiFi Sonar backup")) {
                        Label("Экспорт копии", systemImage: "square.and.arrow.up")
                    }
                    Button { showImporter = true } label: {
                        Label("Импорт", systemImage: "square.and.arrow.down")
                    }
                }.font(.subheadline)
                if let importMessage { Text(importMessage).font(.caption).foregroundStyle(.secondary) }
                if events.isEmpty { Text("История пока пуста.").foregroundStyle(.secondary) }
                else {
                    ForEach(events) { event in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.localizedTitle).font(.subheadline.weight(.semibold))
                            Text(event.date.formatted(Date.FormatStyle(date: .numeric, time: .shortened).locale(Locale(identifier: appLanguage)))).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .onAppear { events = HistoryStore.load() }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                events = try HistoryStore.importJSON(data)
                importMessage = "Импортировано событий: \(events.count)"
            } catch {
                importMessage = String(localized: "Не удалось импортировать резервную копию.")
            }
        }
    }
}

struct SettingsView: View {
    @Binding var appLanguage: String
    @Binding var darkTheme: Bool
    var body: some View {
        NavigationStack {
            Form {
                Section("Язык") {
                    Picker("Язык приложения", selection: $appLanguage) {
                        Text("Русский").tag("ru")
                        Text("English").tag("en")
                    }.pickerStyle(.segmented)
                }
                Section("Внешний вид") {
                    Toggle("Тёмная тема", isOn: $darkTheme)
                }
            }.navigationTitle("Настройки").navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AboutView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("WiFi Sonar") {
                    Text("Нативная версия для iPhone.")
                    Text("Некоторые функции Android ограничены публичными API iOS. Приложение показывает только реальные доступные данные.")
                }
                Section("Платформа") { LabeledContent("Минимальная iOS", value: "16.0") }
            }.navigationTitle("О программе").navigationBarTitleDisplayMode(.inline)
        }
    }
}

@MainActor
final class NetworkStatusService: ObservableObject {
    @Published var isWiFi = false
    @Published var statusText = String(localized: "Не определено")
    @Published var ipAddress: String?
    @Published var currentSSID: String?
    @Published var currentBSSID: String?
    @Published var securityType: String?
    @Published var currentInfoNote: String?
    private let monitor = NWPathMonitor()
    private var started = false
    func start() {
        guard !started else { return }
        started = true
        monitor.pathUpdateHandler = { [weak self] path in
            let wifi = path.usesInterfaceType(.wifi)
            let status = path.status == .satisfied ? String(localized: "Доступен") : String(localized: "Нет доступа")
            let ip = Self.ipv4Address()
            DispatchQueue.main.async {
                self?.isWiFi = wifi
                self?.statusText = status
                self?.ipAddress = ip
                HistoryStore.recordPathChange(isWiFi: wifi, isAvailable: path.status == .satisfied, ipAddress: ip)
            }
        }
        monitor.start(queue: DispatchQueue(label: "wifi.sonar.path"))
    }
    func refreshInterface() { ipAddress = Self.ipv4Address() }

    func readCurrentWiFiInfo() {
        Task {
            let current = await NEHotspotNetwork.fetchCurrent()
            if let current {
                currentSSID = current.ssid
                currentBSSID = current.bssid
                securityType = String(describing: current.securityType)
                currentInfoNote = nil
            } else {
                currentSSID = nil
                currentBSSID = nil
                securityType = nil
                currentInfoNote = String(localized: "iOS не предоставила параметры сети. Проверьте entitlement Access Wi-Fi Information и требования Apple к доступу.")
            }
        }
    }

    nonisolated private static func ipv4Address() -> String? {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return nil }
        defer { freeifaddrs(head) }
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let item = cursor {
            let value = item.pointee
            if let addr = value.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) {
                let name = String(cString: value.ifa_name)
                if name == "en0" {
                    var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    let result = getnameinfo(addr, socklen_t(addr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
                    if result == 0 { return String(cString: host) }
                }
            }
            cursor = value.ifa_next
        }
        return nil
    }
}

@MainActor
final class DiagnosticsService: ObservableObject {
    @Published var logs: [String] = []
    @Published var services: [String] = []
    private var browser: NWBrowser?
    private var connection: NWConnection?

    func scanTCP(host: String, ports rawPorts: String) {
        let octets = host.split(separator: ".").compactMap { UInt8($0) }
        guard octets.count == 4, octets.map(String.init).joined(separator: ".") == host else {
            logs.append(String(localized: "Ошибка: введите IPv4-адрес устройства в локальной сети."))
            return
        }
        let a = Int(octets[0]), b = Int(octets[1])
        let privateAddress = a == 10 || a == 192 && b == 168 || a == 172 && (16...31).contains(b) || a == 169 && b == 254
        guard privateAddress else {
            logs.append(String(localized: "Проверка ограничена частными IPv4-адресами локальной сети."))
            return
        }
        let selected = Array(Set(rawPorts.split(separator: ",").compactMap { UInt16($0.trimmingCharacters(in: .whitespaces)) }.filter { $0 > 0 })).sorted().prefix(32)
        guard !selected.isEmpty else {
            logs.append(String(localized: "Ошибка: укажите хотя бы один TCP-порт."))
            return
        }
        logs.append("TCP-сканирование \(host) · портов: \(selected.count)")
        for port in selected {
            guard let endpointPort = NWEndpoint.Port(rawValue: port) else { continue }
            let probe = NWConnection(host: NWEndpoint.Host(host), port: endpointPort, using: .tcp)
            let start = DispatchTime.now()
            var completed = false
            let timeout = DispatchWorkItem { [weak self] in
                guard !completed else { return }
                completed = true
                DispatchQueue.main.async { self?.logs.append("\(port)/tcp — таймаут или закрыт") }
                probe.cancel()
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.5, execute: timeout)
            probe.stateUpdateHandler = { [weak self] state in
                guard !completed else { return }
                switch state {
                case .ready:
                    completed = true
                    timeout.cancel()
                    let ms = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                    DispatchQueue.main.async { self?.logs.append("\(port)/tcp — открыт · \(String(format: "%.1f", ms)) мс") }
                    probe.cancel()
                case .failed:
                    completed = true
                    timeout.cancel()
                    DispatchQueue.main.async { self?.logs.append("\(port)/tcp — закрыт или недоступен") }
                    probe.cancel()
                default: break
                }
            }
            probe.start(queue: DispatchQueue(label: "wifi.sonar.tcp.\(port)"))
        }
    }

    func startBonjourDiscovery() {
        services.removeAll()
        browser?.cancel()
        let browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: .tcp)
        self.browser = browser
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            let found = results.map { String(describing: $0.endpoint) }
            DispatchQueue.main.async { self?.services = found }
        }
        browser.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async { self?.logs.append("Bonjour: \(state)") }
        }
        browser.start(queue: DispatchQueue(label: "wifi.sonar.bonjour"))
    }
}

private final class ScanProbeCompletionGate: @unchecked Sendable {
    private let lock = NSLock()
    private var isFinished = false

    func finishOnce() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !isFinished else { return false }
        isFinished = true
        return true
    }
}

struct SurveyPoint: Identifiable {
    let id = UUID()
    var title: String
    var x: CGFloat
    var y: CGFloat
    var kind: String
}

struct HistoryEvent: Codable, Identifiable {
    var id: UUID
    var kind: String
    var date: Date

    enum CodingKeys: String, CodingKey { case id, kind, title, date }

    init(id: UUID, kind: String, date: Date) {
        self.id = id
        self.kind = kind
        self.date = date
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        date = try values.decode(Date.self, forKey: .date)
        if let storedKind = try values.decodeIfPresent(String.self, forKey: .kind) {
            kind = storedKind
        } else {
            // Migration from the initial prototype, which stored localized event titles.
            let legacyTitle = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
            if legacyTitle == "Подключён Wi-Fi" || legacyTitle == "Wi-Fi connected" {
                kind = "wifi"
            } else if legacyTitle == "Доступно другое сетевое подключение" || legacyTitle == "Another network connection is available" {
                kind = "other"
            } else {
                kind = "offline"
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(kind, forKey: .kind)
        try values.encode(date, forKey: .date)
    }

    var localizedTitle: String {
        switch kind {
        case "wifi": String(localized: "Подключён Wi-Fi")
        case "other": String(localized: "Доступно другое сетевое подключение")
        default: String(localized: "Сетевое подключение недоступно")
        }
    }
}

enum HistoryStore {
    static let key = "wifiSonar.history.v1"
    static func load() -> [HistoryEvent] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let values = try? JSONDecoder().decode([HistoryEvent].self, from: data) else { return [] }
        return values
    }
    static func save(_ events: [HistoryEvent]) {
        if let data = try? JSONEncoder().encode(events) { UserDefaults.standard.set(data, forKey: key) }
    }

    static func recordPathChange(isWiFi: Bool, isAvailable: Bool, ipAddress: String?) {
        let signature = "\(isWiFi)|\(isAvailable)|\(ipAddress ?? "unknown")"
        let previous = UserDefaults.standard.string(forKey: "wifiSonar.lastPathSignature")
        guard previous != signature else { return }
        UserDefaults.standard.set(signature, forKey: "wifiSonar.lastPathSignature")
        let kind = isWiFi ? "wifi" : (isAvailable ? "other" : "offline")
        var events = load()
        events.insert(HistoryEvent(id: UUID(), kind: kind, date: Date()), at: 0)
        save(Array(events.prefix(500)))
    }

    static func exportJSON() -> String {
        let backup = BackupDocument(schemaVersion: 1, exportedAt: Date(), events: load())
        guard let data = try? JSONEncoder.pretty.encode(backup) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    static func importJSON(_ data: Data) throws -> [HistoryEvent] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let backup = try? decoder.decode(BackupDocument.self, from: data) {
            guard backup.schemaVersion == 1 else { throw BackupError.unsupportedVersion }
            save(backup.events)
            return backup.events
        }
        // Migration path: accept the original v1 history array (Foundation date encoding).
        let legacyDecoder = JSONDecoder()
        let legacy = try legacyDecoder.decode([HistoryEvent].self, from: data)
        save(legacy)
        return legacy
    }
}

struct BackupDocument: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let events: [HistoryEvent]
}

enum BackupError: Error { case unsupportedVersion }

extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
