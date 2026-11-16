import SwiftUI
import Network
import SystemConfiguration
import Darwin
import UIKit

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
    static let cyan = Color(red: 84/255, green: 244/255, blue: 1)
    static let violet = Color(red: 155/255, green: 140/255, blue: 1)
    static let magenta = Color(red: 1, green: 79/255, blue: 216/255)
    static let green = Color(red: 100/255, green: 247/255, blue: 176/255)
    static let border = Color(red: 57/255, green: 49/255, blue: 95/255)
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
                HStack { Text(network.isWiFi ? "Wi-Fi" : "Сетевой путь"); Spacer(); Text(network.statusText).foregroundStyle(.secondary) }
                if let ip = network.ipAddress { infoRow("Локальный IP", ip) }
                else { unavailableRow("Локальный IP") }
                unavailableRow("SSID")
                unavailableRow("BSSID")
                unavailableRow("RSSI / уровень сигнала")
                unavailableRow("Частота / канал / ширина")
                unavailableRow("Защита Wi-Fi")
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
        HStack { Text(title); Spacer(); Text("Недоступно").foregroundStyle(.secondary) }.font(.subheadline)
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
    @State private var host = "1.1.1.1"
    @State private var port = "443"
    var body: some View {
        ScreenScroll(title: "Диагностика") {
            SonarCard {
                Text("TCP-проверка доступности").font(.headline)
                TextField("Адрес или имя узла", text: $host).textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(.roundedBorder)
                TextField("Порт", text: $port).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                Button { diagnostics.checkTCP(host: host, port: UInt16(port) ?? 443) } label: {
                    Label("Проверить TCP", systemImage: "play.fill")
                }.buttonStyle(.borderedProminent).tint(SonarTheme.cyan)
                Text("Это проверка TCP-соединения, а не ICMP ping.").font(.caption).foregroundStyle(.secondary)
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
                    .simultaneousGesture(MagnificationGesture().onChanged { value in
                        zoom = min(max(value, 0.65), 2.5)
                    })
                    .simultaneousGesture(DragGesture(minimumDistance: 0).onEnded { gesture in
                        let point = gesture.location
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
    var body: some View {
        ScreenScroll(title: "История") {
            SonarCard {
                Text("Наблюдаемые события").font(.headline)
                Text("iOS не предоставляет системную историю Wi-Fi-подключений. Здесь будут отображаться только события, которые приложение реально наблюдало во время работы.")
                    .font(.subheadline).foregroundStyle(.secondary)
                if events.isEmpty { Text("История пока пуста.").foregroundStyle(.secondary) }
                else {
                    ForEach(events) { event in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.title).font(.subheadline.weight(.semibold))
                            Text(event.date.formatted()).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
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
    @Published var statusText = "Не определено"
    @Published var ipAddress: String?
    private let monitor = NWPathMonitor()
    private var started = false
    func start() {
        guard !started else { return }
        started = true
        monitor.pathUpdateHandler = { [weak self] path in
            let wifi = path.usesInterfaceType(.wifi)
            let status = path.status == .satisfied ? "Доступен" : "Нет доступа"
            let ip = Self.ipv4Address()
            DispatchQueue.main.async {
                self?.isWiFi = wifi
                self?.statusText = status
                self?.ipAddress = ip
            }
        }
        monitor.start(queue: DispatchQueue(label: "wifi.sonar.path"))
    }
    func refreshInterface() { ipAddress = Self.ipv4Address() }
    private static func ipv4Address() -> String? {
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

    func checkTCP(host: String, port: UInt16) {
        guard !host.trimmingCharacters(in: .whitespaces).isEmpty else {
            logs.append("Ошибка: укажите адрес узла.")
            return
        }
        guard let endpointPort = NWEndpoint.Port(rawValue: port) else {
            logs.append("Ошибка: неверный порт.")
            return
        }
        logs.append("TCP \(host):\(port) — проверка начата")
        let connection = NWConnection(host: NWEndpoint.Host(host), port: endpointPort, using: .tcp)
        self.connection = connection
        let start = DispatchTime.now()
        connection.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    let ms = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                    self?.logs.append(String(format: "TCP соединение установлено · %.1f мс", ms))
                    connection.cancel()
                case .failed(let error):
                    self?.logs.append("TCP ошибка: \(error.localizedDescription)")
                    connection.cancel()
                default: break
                }
            }
        }
        connection.start(queue: DispatchQueue(label: "wifi.sonar.tcp"))
    }

    func startBonjourDiscovery() {
        services.removeAll()
        browser?.cancel()
        let browser = NWBrowser(for: .bonjour(type: "_services._dns-sd._udp", domain: nil), using: .tcp)
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

struct SurveyPoint: Identifiable {
    let id = UUID()
    var title: String
    var x: CGFloat
    var y: CGFloat
    var kind: String
}

struct HistoryEvent: Codable, Identifiable {
    var id: UUID
    var title: String
    var date: Date
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
}
