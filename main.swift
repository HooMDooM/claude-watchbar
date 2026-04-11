import Cocoa
import SwiftUI
import Charts
import SQLite3

// ═══════════════════════════════════════════════════════════════
// MARK: - Constants
// ═══════════════════════════════════════════════════════════════

let kDbPath  = (NSHomeDirectory() as NSString).appendingPathComponent(".claude/usage.db")
let kCliPath = (NSHomeDirectory() as NSString).appendingPathComponent("Documents/claude-usage/cli.py")

let kDateFmt: DateFormatter = {
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
}()

// ═══════════════════════════════════════════════════════════════
// MARK: - Localization
// ═══════════════════════════════════════════════════════════════

enum Lang: String, CaseIterable, Identifiable {
    case ru = "ru"; case en = "en"; case de = "de"; case fr = "fr"
    case es = "es"; case tr = "tr"; case ar = "ar"
    var id: String { rawValue }
    var flag: String {
        switch self {
        case .ru: return "🇷🇺"; case .en: return "🇬🇧"; case .de: return "🇩🇪"; case .fr: return "🇫🇷"
        case .es: return "🇪🇸"; case .tr: return "🇹🇷"; case .ar: return "🇸🇦"
        }
    }
    var label: String {
        switch self {
        case .ru: return "Русский"; case .en: return "English"; case .de: return "Deutsch"; case .fr: return "Français"
        case .es: return "Español"; case .tr: return "Türkçe"; case .ar: return "العربية"
        }
    }
}

// swiftlint:disable type_body_length
struct L {
    let today, yesterday, days7, days30, days90, allTime: String
    let sessions, turns, input, output, cacheRead, cacheWrite, total, cost: String
    let tokensByDay, models, topProjects, costByModel: String
    let noData, model, cRead, cWrite, totalCol, totalRow: String
    let scanning, updateIn, refresh, openDash, quit: String
    let session5h, weekly: String

    static let all: [String: L] = [
        "ru": L(today: "Сегодня", yesterday: "Вчера", days7: "7 дней", days30: "30 дней", days90: "90 дней", allTime: "Всё время",
               sessions: "сессии", turns: "ходы", input: "ввод", output: "вывод", cacheRead: "кэш чт.", cacheWrite: "кэш зап.", total: "всего", cost: "расход",
               tokensByDay: "ТОКЕНЫ ПО ДНЯМ", models: "МОДЕЛИ", topProjects: "ТОП ПРОЕКТЫ", costByModel: "СТОИМОСТЬ ПО МОДЕЛЯМ",
               noData: "Нет данных", model: "Модель", cRead: "Кэш Чт", cWrite: "Кэш Зп", totalCol: "Итого", totalRow: "Итого",
               scanning: "Сканирование...", updateIn: "Обновление через", refresh: "Обновить", openDash: "Веб-дашборд", quit: "Выйти",
               session5h: "Сессия (5ч)", weekly: "Неделя"),
        "en": L(today: "Today", yesterday: "Yesterday", days7: "7 days", days30: "30 days", days90: "90 days", allTime: "All time",
               sessions: "sessions", turns: "turns", input: "input", output: "output", cacheRead: "cache rd", cacheWrite: "cache wr", total: "total", cost: "cost",
               tokensByDay: "TOKENS BY DAY", models: "MODELS", topProjects: "TOP PROJECTS", costByModel: "COST BY MODEL",
               noData: "No data", model: "Model", cRead: "C.Read", cWrite: "C.Write", totalCol: "Total", totalRow: "Total",
               scanning: "Scanning...", updateIn: "Update in", refresh: "Refresh", openDash: "Web dashboard", quit: "Quit",
               session5h: "Session (5h)", weekly: "Weekly"),
        "de": L(today: "Heute", yesterday: "Gestern", days7: "7 Tage", days30: "30 Tage", days90: "90 Tage", allTime: "Gesamt",
               sessions: "Sitzungen", turns: "Züge", input: "Eingabe", output: "Ausgabe", cacheRead: "Cache Ls", cacheWrite: "Cache Schr", total: "Gesamt", cost: "Kosten",
               tokensByDay: "TOKENS PRO TAG", models: "MODELLE", topProjects: "TOP-PROJEKTE", costByModel: "KOSTEN PRO MODELL",
               noData: "Keine Daten", model: "Modell", cRead: "C.Lesen", cWrite: "C.Schr", totalCol: "Gesamt", totalRow: "Gesamt",
               scanning: "Scannen...", updateIn: "Aktualisierung in", refresh: "Aktualisieren", openDash: "Web-Dashboard", quit: "Beenden",
               session5h: "Sitzung (5h)", weekly: "Wöchentlich"),
        "fr": L(today: "Aujourd'hui", yesterday: "Hier", days7: "7 jours", days30: "30 jours", days90: "90 jours", allTime: "Total",
               sessions: "sessions", turns: "tours", input: "entrée", output: "sortie", cacheRead: "cache lec", cacheWrite: "cache écr", total: "total", cost: "coût",
               tokensByDay: "TOKENS PAR JOUR", models: "MODÈLES", topProjects: "TOP PROJETS", costByModel: "COÛT PAR MODÈLE",
               noData: "Aucune donnée", model: "Modèle", cRead: "C.Lire", cWrite: "C.Écr", totalCol: "Total", totalRow: "Total",
               scanning: "Analyse...", updateIn: "Mise à jour dans", refresh: "Actualiser", openDash: "Tableau de bord", quit: "Quitter",
               session5h: "Session (5h)", weekly: "Hebdo"),
        "es": L(today: "Hoy", yesterday: "Ayer", days7: "7 días", days30: "30 días", days90: "90 días", allTime: "Todo",
               sessions: "sesiones", turns: "turnos", input: "entrada", output: "salida", cacheRead: "caché lec", cacheWrite: "caché esc", total: "total", cost: "costo",
               tokensByDay: "TOKENS POR DÍA", models: "MODELOS", topProjects: "TOP PROYECTOS", costByModel: "COSTO POR MODELO",
               noData: "Sin datos", model: "Modelo", cRead: "C.Leer", cWrite: "C.Escr", totalCol: "Total", totalRow: "Total",
               scanning: "Escaneando...", updateIn: "Actualización en", refresh: "Actualizar", openDash: "Panel web", quit: "Salir",
               session5h: "Sesión (5h)", weekly: "Semanal"),
        "tr": L(today: "Bugün", yesterday: "Dün", days7: "7 gün", days30: "30 gün", days90: "90 gün", allTime: "Tümü",
               sessions: "oturum", turns: "tur", input: "giriş", output: "çıkış", cacheRead: "önb. oku", cacheWrite: "önb. yaz", total: "toplam", cost: "maliyet",
               tokensByDay: "GÜNLÜK TOKENLER", models: "MODELLER", topProjects: "EN İYİ PROJELER", costByModel: "MODEL MALİYETİ",
               noData: "Veri yok", model: "Model", cRead: "Ö.Oku", cWrite: "Ö.Yaz", totalCol: "Toplam", totalRow: "Toplam",
               scanning: "Taranıyor...", updateIn: "Güncelleme", refresh: "Yenile", openDash: "Web paneli", quit: "Çıkış",
               session5h: "Oturum (5s)", weekly: "Haftalık"),
        "ar": L(today: "اليوم", yesterday: "أمس", days7: "٧ أيام", days30: "٣٠ يوم", days90: "٩٠ يوم", allTime: "الكل",
               sessions: "جلسات", turns: "أدوار", input: "إدخال", output: "إخراج", cacheRead: "قراءة", cacheWrite: "كتابة", total: "المجموع", cost: "التكلفة",
               tokensByDay: "الرموز حسب اليوم", models: "النماذج", topProjects: "أهم المشاريع", costByModel: "التكلفة حسب النموذج",
               noData: "لا توجد بيانات", model: "نموذج", cRead: "ق.كاش", cWrite: "ك.كاش", totalCol: "المجموع", totalRow: "المجموع",
               scanning: "...جارٍ المسح", updateIn: "التحديث خلال", refresh: "تحديث", openDash: "لوحة الويب", quit: "خروج",
               session5h: "الجلسة (٥س)", weekly: "أسبوعي"),
    ]
}
// swiftlint:enable type_body_length

func detectSystemLang() -> String {
    let preferred = Locale.preferredLanguages.first ?? "en"
    let code = String(preferred.prefix(2))
    return L.all[code] != nil ? code : "en"
}

class I18n: ObservableObject {
    @Published var lang: String {
        didSet {
            UserDefaults.standard.set(lang, forKey: "cu_lang")
            current = L.all[lang] ?? L.all["en"]!
        }
    }
    @Published var current: L

    init() {
        let saved = UserDefaults.standard.string(forKey: "cu_lang") ?? detectSystemLang()
        self.lang = saved
        self.current = L.all[saved] ?? L.all["en"]!
    }
}

let i18n = I18n()
var t: L { i18n.current }

// ═══════════════════════════════════════════════════════════════
// MARK: - Period
// ═══════════════════════════════════════════════════════════════

enum Period: String, CaseIterable, Identifiable {
    case today   = "today"
    case week    = "week"
    case month   = "month"
    case quarter = "quarter"
    case all     = "all"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: return t.today; case .week: return t.days7; case .month: return t.days30
        case .quarter: return t.days90; case .all: return t.allTime
        }
    }

    func whereFor(_ col: String = "timestamp") -> String {
        switch self {
        case .today:   return "date(\(col),'localtime')=date('now','localtime')"
        case .week:    return "date(\(col),'localtime')>=date('now','-7 days','localtime')"
        case .month:   return "date(\(col),'localtime')>=date('now','-30 days','localtime')"
        case .quarter: return "date(\(col),'localtime')>=date('now','-90 days','localtime')"
        case .all:     return "1=1"
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Pricing & Helpers
// ═══════════════════════════════════════════════════════════════

struct Pricing {
    let inp: Double, out: Double, cw: Double, cr: Double
    static let opus   = Pricing(inp: 5.0,  out: 25.0, cw: 6.25, cr: 0.5)
    static let sonnet = Pricing(inp: 3.0,  out: 15.0, cw: 3.75, cr: 0.3)
    static let haiku  = Pricing(inp: 1.0,  out: 5.0,  cw: 1.25, cr: 0.1)

    static func of(_ m: String) -> Pricing? {
        let l = m.lowercased()
        if l.contains("opus")   { return .opus }
        if l.contains("sonnet") { return .sonnet }
        if l.contains("haiku")  { return .haiku }
        return nil
    }
}

func costOf(inp: Int64, out: Int64, cr: Int64, cw: Int64, m: String) -> Double {
    guard let p = Pricing.of(m) else { return 0 }
    return Double(inp)/1e6*p.inp + Double(out)/1e6*p.out + Double(cw)/1e6*p.cw + Double(cr)/1e6*p.cr
}

func shortName(_ m: String) -> String {
    // claude-opus-4-6 → Opus 4.6, claude-sonnet-4-5-20250929 → Sonnet 4.5
    let l = m.lowercased()
    let family: String
    if l.contains("opus")        { family = "Opus" }
    else if l.contains("sonnet") { family = "Sonnet" }
    else if l.contains("haiku")  { family = "Haiku" }
    else { return String(m.prefix(15)) }

    // Extract version: find "4-5" or "4-6" pattern after family name
    let parts = l.components(separatedBy: "-")
    if let fi = parts.firstIndex(where: { $0.contains(family.lowercased()) }),
       fi + 2 < parts.count,
       let major = Int(parts[fi + 1]),
       let minor = Int(parts[fi + 2]) {
        return "\(family) \(major).\(minor)"
    }
    return family
}

func mColor(_ m: String) -> Color {
    let l = m.lowercased()
    if l.contains("opus")   { return Color(red: 0.7, green: 0.3, blue: 1.0) }
    if l.contains("sonnet") { return Color(red: 0.3, green: 0.6, blue: 1.0) }
    if l.contains("haiku")  { return Color(red: 0.3, green: 0.9, blue: 0.5) }
    return .gray
}

func fT(_ n: Int64) -> String {
    if n >= 1_000_000_000 { return String(format: "%.2fB", Double(n)/1e9) }
    if n >= 1_000_000     { return String(format: "%.2fM", Double(n)/1e6) }
    if n >= 1000          { return String(format: "%.1fK", Double(n)/1e3) }
    return "\(n)"
}

func fC(_ c: Double) -> String {
    if c >= 1000 { return String(format: "$%.0f", c) }
    return String(format: "$%.2f", c)
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Plan Config & Limits
// ═══════════════════════════════════════════════════════════════

struct LimitInfo {
    var plan: String = "Max 20x"
    var sessionPct: Double = 0; var weeklyPct: Double = 0
    var sessionReset: String = ""; var weeklyReset: String = ""
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Anthropic API Rate Limits
// ═══════════════════════════════════════════════════════════════

func readClaudeOAuthToken() -> String? {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/security")
    task.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.nullDevice
    do { try task.run() } catch { return nil }
    task.waitUntilExit()
    guard task.terminationStatus == 0 else { return nil }

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let str = String(data: data, encoding: .utf8),
          let jsonData = str.data(using: .utf8),
          let j = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
          let oauth = j["claudeAiOauth"] as? [String: Any],
          let token = oauth["accessToken"] as? String else {
        return nil
    }
    return token
}

struct ApiLimits {
    var session5hPct: Double?
    var weekly7dPct: Double?
    var session5hResetUnix: Int?
    var weekly7dResetUnix: Int?
    var plan: String?
}

// Cache to avoid hammering API
var apiLimitsCache: (info: ApiLimits, timestamp: Date)?
let apiCacheTTL: TimeInterval = 25  // seconds

func fetchApiLimits() -> ApiLimits? {
    // Return cached if fresh
    if let c = apiLimitsCache, Date().timeIntervalSince(c.timestamp) < apiCacheTTL {
        return c.info
    }

    guard let token = readClaudeOAuthToken() else { return nil }

    var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
    req.httpMethod = "POST"
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
    req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = """
        {"model":"claude-haiku-4-5","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}
        """.data(using: .utf8)
    req.timeoutInterval = 10

    let sem = DispatchSemaphore(value: 0)
    var result: ApiLimits?

    URLSession.shared.dataTask(with: req) { _, response, _ in
        defer { sem.signal() }
        guard let http = response as? HTTPURLResponse else { return }
        var info = ApiLimits()
        for (k, v) in http.allHeaderFields {
            guard let key = (k as? String)?.lowercased(),
                  let val = v as? String else { continue }
            switch key {
            case "anthropic-ratelimit-unified-5h-utilization":
                info.session5hPct = Double(val)
            case "anthropic-ratelimit-unified-7d-utilization":
                info.weekly7dPct = Double(val)
            case "anthropic-ratelimit-unified-5h-reset":
                info.session5hResetUnix = Int(val)
            case "anthropic-ratelimit-unified-7d-reset":
                info.weekly7dResetUnix = Int(val)
            default: break
            }
        }
        if info.session5hPct != nil || info.weekly7dPct != nil {
            result = info
        }
    }.resume()

    _ = sem.wait(timeout: .now() + 12)

    if let r = result {
        apiLimitsCache = (r, Date())
    }
    return result
}

func fmtUnixReset(_ unix: Int) -> String {
    let seconds = unix - Int(Date().timeIntervalSince1970)
    return fmtTimeLeft(seconds)
}

struct PlanCfg {
    var plan: String; var sessionLimit: Double; var weeklyLimit: Double
}

func loadPlanCfg() -> PlanCfg {
    let path = (NSHomeDirectory() as NSString).appendingPathComponent(".claude/usage-bar.json")
    if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
       let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        return PlanCfg(
            plan: j["plan"] as? String ?? "Max 20x",
            sessionLimit: j["session_limit"] as? Double ?? 80,
            weeklyLimit: j["weekly_limit"] as? Double ?? 2000)
    }
    let cfg = PlanCfg(plan: "Max 20x", sessionLimit: 80, weeklyLimit: 2000)
    let j: [String: Any] = ["plan": cfg.plan, "session_limit": cfg.sessionLimit, "weekly_limit": cfg.weeklyLimit]
    if let d = try? JSONSerialization.data(withJSONObject: j, options: .prettyPrinted) {
        try? d.write(to: URL(fileURLWithPath: path))
    }
    return cfg
}

func fetchCostInWindow(_ hours: Int) -> Double {
    dbRun("""
        SELECT COALESCE(model,'unknown'),
               COALESCE(SUM(input_tokens),0), COALESCE(SUM(output_tokens),0),
               COALESCE(SUM(cache_read_tokens),0), COALESCE(SUM(cache_creation_tokens),0)
        FROM turns
        WHERE datetime(timestamp,'localtime') >= datetime('now','-\(hours) hours','localtime')
        GROUP BY model
    """).reduce(0.0) { $0 + costOf(inp: i64($1,1), out: i64($1,2), cr: i64($1,3), cw: i64($1,4), m: str($1,0)) }
}

func fmtTimeLeft(_ seconds: Int) -> String {
    if seconds <= 0 { return "" }
    let h = seconds / 3600; let m = (seconds % 3600) / 60
    if h >= 24 { return "\(h/24)d \(h%24)h" }
    return "\(h)h \(m)m"
}

func fetchOldestTurnAge(_ hours: Int) -> Int {
    // Returns seconds remaining until the window resets (windowSize - age of oldest turn)
    let rows = dbRun("""
        SELECT MIN(timestamp) FROM turns
        WHERE datetime(timestamp,'localtime') >= datetime('now','-\(hours) hours','localtime')
    """)
    guard let ts = rows.first?.first as? String, !ts.isEmpty else { return 0 }
    let fmt = ISO8601DateFormatter()
    fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let fmt2 = ISO8601DateFormatter()
    fmt2.formatOptions = [.withInternetDateTime]
    if let d = fmt.date(from: ts) ?? fmt2.date(from: ts) {
        let age = Int(Date().timeIntervalSince(d))
        return max(0, hours * 3600 - age)
    }
    return 0
}

func fetchLimits() -> LimitInfo {
    let cfg = loadPlanCfg()
    var info = LimitInfo(plan: cfg.plan)

    // Try real Anthropic API first (exact values from their servers)
    if let api = fetchApiLimits() {
        if let p = api.session5hPct { info.sessionPct = p }
        if let p = api.weekly7dPct  { info.weeklyPct  = p }
        if let r = api.session5hResetUnix { info.sessionReset = fmtUnixReset(r) }
        if let r = api.weekly7dResetUnix  { info.weeklyReset  = fmtUnixReset(r) }
        return info
    }

    // Fallback: approximate from local token data if API unreachable
    let sc = fetchCostInWindow(5)
    let wc = fetchCostInWindow(168)
    info.sessionPct = cfg.sessionLimit > 0 ? min(sc / cfg.sessionLimit, 1.0) : 0
    info.weeklyPct  = cfg.weeklyLimit > 0  ? min(wc / cfg.weeklyLimit, 1.0)  : 0
    info.sessionReset = fmtTimeLeft(fetchOldestTurnAge(5))
    info.weeklyReset  = fmtTimeLeft(fetchOldestTurnAge(168))
    return info
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Status Bar Image (two limit bars)
// ═══════════════════════════════════════════════════════════════

func pctColor(_ p: Double) -> NSColor {
    if p < 0.5  { return .systemGreen }
    if p < 0.8  { return .systemYellow }
    return .systemRed
}

func createBarImage(sPct: Double, wPct: Double, active: Bool = false) -> NSImage {
    let w: CGFloat = 30, h: CGFloat = 18
    let bh: CGFloat = 5, gap: CGFloat = 3, pad: CGFloat = 2, cr: CGFloat = 2

    let img = NSImage(size: NSSize(width: w, height: h))
    img.lockFocus()
    let bg = active ? NSColor(white: 0.5, alpha: 1.0) : NSColor(white: 0.3, alpha: 1.0)
    let sColor = active ? pctColor(sPct) : NSColor.white
    let wColor = active ? pctColor(wPct) : NSColor.white

    // Top bar = session (5h)
    let sy = h - bh - pad
    bg.setFill()
    NSBezierPath(roundedRect: NSRect(x: 0, y: sy, width: w, height: bh), xRadius: cr, yRadius: cr).fill()
    let sw = max(3, min(w, w * CGFloat(min(sPct, 1.0))))
    if sPct > 0 {
        sColor.setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: sy, width: sw, height: bh), xRadius: cr, yRadius: cr).fill()
    }

    // Bottom bar = weekly (7d)
    let wy = sy - bh - gap
    bg.setFill()
    NSBezierPath(roundedRect: NSRect(x: 0, y: wy, width: w, height: bh), xRadius: cr, yRadius: cr).fill()
    let ww = max(3, min(w, w * CGFloat(min(wPct, 1.0))))
    if wPct > 0 {
        wColor.setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: wy, width: ww, height: bh), xRadius: cr, yRadius: cr).fill()
    }

    img.unlockFocus()
    img.isTemplate = false
    return img
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Data Models
// ═══════════════════════════════════════════════════════════════

struct Summary {
    var sessions: Int64 = 0; var turns: Int64 = 0
    var input: Int64 = 0;    var output: Int64 = 0
    var cacheR: Int64 = 0;   var cacheW: Int64 = 0
    var total: Int64 { input + output + cacheR + cacheW }
    var cost: Double = 0
}

struct DayRow: Identifiable {
    let id = UUID(); let day: Date
    let input: Double; let output: Double; let cacheR: Double; let cacheW: Double
}

struct TokenPt: Identifiable {
    let id = UUID(); let day: Date; let cat: String; let val: Double
}

struct ModelRow: Identifiable {
    let id = UUID(); let model: String
    let input: Int64; let output: Int64; let cacheR: Int64; let cacheW: Int64; let turns: Int64
    var total: Int64 { input + output + cacheR + cacheW }
    var cost: Double    { costOf(inp: input, out: output, cr: cacheR, cw: cacheW, m: model) }
    var inpCost: Double { guard let p = Pricing.of(model) else { return 0 }; return Double(input)/1e6*p.inp }
    var outCost: Double { guard let p = Pricing.of(model) else { return 0 }; return Double(output)/1e6*p.out }
    var crCost: Double  { guard let p = Pricing.of(model) else { return 0 }; return Double(cacheR)/1e6*p.cr }
    var cwCost: Double  { guard let p = Pricing.of(model) else { return 0 }; return Double(cacheW)/1e6*p.cw }
    var color: Color { mColor(model) }
}

struct ProjRow: Identifiable {
    let id = UUID(); let name: String; let tokens: Int64; let cost: Double
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Database
// ═══════════════════════════════════════════════════════════════

func dbRun(_ sql: String) -> [[Any]] {
    var db: OpaquePointer?
    guard sqlite3_open_v2(kDbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return [] }
    defer { sqlite3_close(db) }
    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
    defer { sqlite3_finalize(stmt) }
    let n = sqlite3_column_count(stmt)
    var rows: [[Any]] = []
    while sqlite3_step(stmt) == SQLITE_ROW {
        var row: [Any] = []
        for i in 0..<n {
            switch sqlite3_column_type(stmt, i) {
            case SQLITE_INTEGER: row.append(sqlite3_column_int64(stmt, i))
            case SQLITE_TEXT:
                if let p = sqlite3_column_text(stmt, i) { row.append(String(cString: p)) }
                else { row.append("") }
            case SQLITE_FLOAT: row.append(sqlite3_column_double(stmt, i))
            default: row.append(Int64(0))
            }
        }
        rows.append(row)
    }
    return rows
}

func i64(_ row: [Any], _ i: Int) -> Int64 { row.count > i ? (row[i] as? Int64 ?? 0) : 0 }
func str(_ row: [Any], _ i: Int) -> String { row.count > i ? (row[i] as? String ?? "") : "" }

func fetchSummary(_ p: Period) -> Summary {
    let t = dbRun("""
        SELECT COALESCE(SUM(input_tokens),0), COALESCE(SUM(output_tokens),0),
               COALESCE(SUM(cache_read_tokens),0), COALESCE(SUM(cache_creation_tokens),0), COUNT(*)
        FROM turns WHERE \(p.whereFor())
    """).first ?? []
    let sc = dbRun("SELECT COUNT(*) FROM sessions WHERE \(p.whereFor("last_timestamp"))").first
    let mr = dbRun("""
        SELECT COALESCE(model,'unknown'), COALESCE(SUM(input_tokens),0), COALESCE(SUM(output_tokens),0),
               COALESCE(SUM(cache_read_tokens),0), COALESCE(SUM(cache_creation_tokens),0)
        FROM turns WHERE \(p.whereFor()) GROUP BY model
    """)
    let cost = mr.reduce(0.0) { $0 + costOf(inp: i64($1,1), out: i64($1,2), cr: i64($1,3), cw: i64($1,4), m: str($1,0)) }
    return Summary(sessions: i64(sc ?? [], 0), turns: i64(t, 4),
                   input: i64(t, 0), output: i64(t, 1), cacheR: i64(t, 2), cacheW: i64(t, 3), cost: cost)
}

func fetchDaily(_ p: Period) -> [DayRow] {
    dbRun("""
        SELECT date(timestamp,'localtime') as day,
               COALESCE(SUM(input_tokens),0), COALESCE(SUM(output_tokens),0),
               COALESCE(SUM(cache_read_tokens),0), COALESCE(SUM(cache_creation_tokens),0)
        FROM turns WHERE \(p.whereFor()) GROUP BY day ORDER BY day
    """).compactMap { r in
        guard let d = kDateFmt.date(from: str(r, 0)) else { return nil }
        return DayRow(day: d, input: Double(i64(r,1)), output: Double(i64(r,2)),
                      cacheR: Double(i64(r,3)), cacheW: Double(i64(r,4)))
    }
}

func fetchModels(_ p: Period) -> [ModelRow] {
    dbRun("""
        SELECT COALESCE(model,'unknown'), COALESCE(SUM(input_tokens),0), COALESCE(SUM(output_tokens),0),
               COALESCE(SUM(cache_read_tokens),0), COALESCE(SUM(cache_creation_tokens),0), COUNT(*)
        FROM turns WHERE \(p.whereFor()) GROUP BY model ORDER BY SUM(input_tokens+output_tokens) DESC
    """).map { r in
        ModelRow(model: str(r,0), input: i64(r,1), output: i64(r,2),
                 cacheR: i64(r,3), cacheW: i64(r,4), turns: i64(r,5))
    }
}

func fetchProjects(_ p: Period) -> [ProjRow] {
    var proj: [String: (tokens: Int64, cost: Double)] = [:]
    let rows = dbRun("""
        SELECT COALESCE(s.project_name,'unknown') as pname,
               COALESCE(t.model,'unknown') as mname,
               COALESCE(SUM(t.input_tokens),0),
               COALESCE(SUM(t.output_tokens),0),
               COALESCE(SUM(t.cache_read_tokens),0),
               COALESCE(SUM(t.cache_creation_tokens),0)
        FROM turns t JOIN sessions s ON t.session_id=s.session_id
        WHERE \(p.whereFor("t.timestamp")) GROUP BY pname, mname
    """)
    for r in rows {
        let raw = str(r, 0)
        let name = raw.components(separatedBy: "/").last ?? raw
        let c = costOf(inp: i64(r,2), out: i64(r,3), cr: i64(r,4), cw: i64(r,5), m: str(r,1))
        let tokens = i64(r,2) + i64(r,3) + i64(r,4) + i64(r,5)
        let cur = proj[name] ?? (0, 0)
        proj[name] = (cur.tokens + tokens, cur.cost + c)
    }
    return proj.map { ProjRow(name: $0.key, tokens: $0.value.tokens, cost: $0.value.cost) }
        .sorted { $0.tokens > $1.tokens }
        .prefix(8).map { $0 }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - ViewModel
// ═══════════════════════════════════════════════════════════════

class VM: ObservableObject {
    @Published var period: Period = .month { didSet { reload() } }
    @Published var summary = Summary()
    @Published var daily: [DayRow] = []
    @Published var models: [ModelRow] = []
    @Published var projects: [ProjRow] = []
    @Published var countdown = 30
    @Published var scanning = false
    @Published var todayCost: Double = 0
    @Published var limits = LimitInfo()
    var onUpdate: (() -> Void)?
    private var timer: Timer?

    init() {
        reload()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let s = self else { return }
                s.countdown -= 1
                if s.countdown <= 0 { s.scanAndReload() }
            }
        }
    }

    func reload() {
        let p = period
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let s  = fetchSummary(p)
            let d  = fetchDaily(p)
            let m  = fetchModels(p)
            let pr = fetchProjects(p)
            let tc = fetchModels(.today).reduce(0.0) { $0 + $1.cost }
            let li = fetchLimits()
            DispatchQueue.main.async {
                self?.summary  = s
                self?.daily    = d
                self?.models   = m
                self?.projects = pr
                self?.todayCost = tc
                self?.limits   = li
                self?.countdown = 30
                self?.onUpdate?()
            }
        }
    }

    func scanAndReload() {
        guard !scanning else { return }
        scanning = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            proc.arguments = [kCliPath, "scan"]
            proc.standardOutput = FileHandle.nullDevice
            proc.standardError  = FileHandle.nullDevice
            try? proc.run(); proc.waitUntilExit()
            DispatchQueue.main.async { self?.scanning = false }
            self?.reload()
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Views: Summary Cards
// ═══════════════════════════════════════════════════════════════

struct StatCard: View {
    let title: String; let value: String; let color: Color
    var highlight = false

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(highlight ? color.opacity(0.12) : Color.white.opacity(0.04))
        .cornerRadius(5)
    }
}

struct SummaryCards: View {
    let s: Summary
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                StatCard(title: t.sessions, value: fT(s.sessions), color: .purple)
                StatCard(title: t.turns,    value: fT(s.turns),    color: .blue)
                StatCard(title: t.input,    value: fT(s.input),    color: .cyan)
                StatCard(title: t.output,   value: fT(s.output),   color: .green)
            }
            HStack(spacing: 4) {
                StatCard(title: t.cacheRead,  value: fT(s.cacheR), color: .orange)
                StatCard(title: t.cacheWrite, value: fT(s.cacheW), color: .pink)
                StatCard(title: t.total,       value: fT(s.total),  color: .white)
                StatCard(title: t.cost,        value: fC(s.cost),   color: .orange, highlight: true)
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Views: Daily Chart
// ═══════════════════════════════════════════════════════════════

struct DailyChart: View {
    let data: [DayRow]

    var points: [TokenPt] {
        data.flatMap { d in [
            TokenPt(day: d.day, cat: "Input",      val: d.input),
            TokenPt(day: d.day, cat: "Output",     val: d.output),
            TokenPt(day: d.day, cat: "Cache Read",  val: d.cacheR),
            TokenPt(day: d.day, cat: "Cache Write", val: d.cacheW),
        ]}
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHead(t.tokensByDay)

            if data.isEmpty {
                Text(t.noData).font(.caption).foregroundColor(.secondary)
                    .frame(height: 100, alignment: .center)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(points) { p in
                    BarMark(x: .value("Day", p.day, unit: .day),
                            y: .value("Tokens", p.val))
                    .foregroundStyle(by: .value("Type", p.cat))
                }
                .chartForegroundStyleScale([
                    "Input":       Color.blue,
                    "Output":      Color.green,
                    "Cache Read":  Color.orange,
                    "Cache Write": Color.purple,
                ])
                .chartLegend(position: .top, alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        legendDot("Input", .blue)
                        legendDot("Output", .green)
                        legendDot("Cache Read", .orange)
                        legendDot("Cache Write", .purple)
                    }
                    .font(.system(size: 8))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { v in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3)).foregroundStyle(.white.opacity(0.1))
                        AxisValueLabel {
                            if let d = v.as(Double.self) { Text(fT(Int64(d))).font(.system(size: 8)) }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, data.count / 7))) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3)).foregroundStyle(.white.opacity(0.1))
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .font(.system(size: 8))
                    }
                }
                .frame(height: 120)
            }
        }
    }

    func legendDot(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(label).foregroundColor(.secondary)
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Views: Model Donut
// ═══════════════════════════════════════════════════════════════

struct ModelDonut: View {
    let models: [ModelRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHead(t.models)

            if models.isEmpty {
                Text(t.noData).font(.caption).foregroundColor(.secondary)
            } else {
                Chart(models) { m in
                    SectorMark(angle: .value("T", m.total),
                               innerRadius: .ratio(0.55), angularInset: 2)
                    .foregroundStyle(m.color)
                    .cornerRadius(3)
                }
                .frame(height: 100)

                ForEach(models) { m in
                    HStack(spacing: 4) {
                        Circle().fill(m.color).frame(width: 6, height: 6)
                        Text(shortName(m.model)).font(.system(size: 10))
                        Spacer()
                        Text(fT(m.total)).font(.system(size: 10)).foregroundColor(.secondary)
                        let pct = models.reduce(Int64(0)) { $0+$1.total }
                        Text(pct > 0 ? "\(m.total * 100 / pct)%" : "")
                            .font(.system(size: 9)).foregroundColor(.secondary)
                            .frame(width: 28, alignment: .trailing)
                    }
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Views: Projects
// ═══════════════════════════════════════════════════════════════

struct ProjectsList: View {
    let projects: [ProjRow]
    var maxT: Int64 { projects.first?.tokens ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHead(t.topProjects)

            if projects.isEmpty {
                Text(t.noData).font(.caption).foregroundColor(.secondary)
            } else {
                ForEach(projects) { p in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(p.name).font(.system(size: 10)).lineLimit(1)
                            Spacer()
                            Text(fC(p.cost))
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.orange)
                            Text(fT(p.tokens)).font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 42, alignment: .trailing)
                        }
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(LinearGradient(colors: [.blue, .purple],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(4, geo.size.width * CGFloat(p.tokens) / CGFloat(maxT)))
                        }.frame(height: 4)
                    }
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Views: Cost Table
// ═══════════════════════════════════════════════════════════════

struct CostTable: View {
    let models: [ModelRow]

    var known: [ModelRow] { models.filter { Pricing.of($0.model) != nil } }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHead(t.costByModel)

            if known.isEmpty {
                Text(t.noData).font(.caption).foregroundColor(.secondary)
            } else {
                Grid(alignment: .trailing, horizontalSpacing: 4, verticalSpacing: 4) {
                    GridRow {
                        Text(t.model).frame(maxWidth: .infinity, alignment: .leading)
                        Text(t.input);  Text(t.output)
                        Text(t.cRead); Text(t.cWrite); Text(t.totalCol)
                    }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)

                    Divider()

                    ForEach(known) { m in
                        GridRow {
                            HStack(spacing: 3) {
                                Circle().fill(m.color).frame(width: 5, height: 5)
                                Text(shortName(m.model))
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            Text(fC(m.inpCost)); Text(fC(m.outCost))
                            Text(fC(m.crCost));  Text(fC(m.cwCost))
                            Text(fC(m.cost)).fontWeight(.semibold)
                        }
                        .font(.system(size: 10, design: .monospaced))
                    }

                    Divider()

                    GridRow {
                        Text(t.totalRow).frame(maxWidth: .infinity, alignment: .leading).fontWeight(.bold)
                        Text(fC(known.reduce(0) { $0+$1.inpCost }))
                        Text(fC(known.reduce(0) { $0+$1.outCost }))
                        Text(fC(known.reduce(0) { $0+$1.crCost }))
                        Text(fC(known.reduce(0) { $0+$1.cwCost }))
                        Text(fC(known.reduce(0) { $0+$1.cost })).fontWeight(.bold)
                    }
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Views: Token Breakdown (per period, quick stats)
// ═══════════════════════════════════════════════════════════════

struct PeriodCostRow: View {
    let label: String; let icon: String; let cost: Double; let tokens: Int64

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 10)).foregroundColor(.secondary).frame(width: 14)
            Text(label).font(.system(size: 13)).foregroundColor(.primary.opacity(0.7))
                .frame(width: 70, alignment: .leading)
            Spacer()
            Text(fC(cost)).font(.system(size: 13, weight: .semibold, design: .monospaced))
            Text("· \(fT(tokens)) tokens").font(.system(size: 11)).foregroundColor(.secondary)
                .frame(width: 105, alignment: .trailing)
        }
    }
}

struct QuickPeriods: View {
    let periods: [(String, String, Period)]

    @State private var data: [(String, String, Double, Int64)] = []

    init() {
        periods = []
    }

    var body: some View {
        VStack(spacing: 3) {
            ForEach(Array(data.enumerated()), id: \.offset) { _, d in
                PeriodCostRow(label: d.0, icon: d.1, cost: d.2, tokens: d.3)
            }
        }
        .onAppear { loadData() }
    }

    func loadData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let defs: [(String, String, String)] = [
                (t.today,     "sun.max.fill",         "date(timestamp,'localtime')=date('now','localtime')"),
                (t.yesterday, "clock.fill",           "date(timestamp,'localtime')=date('now','-1 day','localtime')"),
                (t.days7,     "calendar",             "date(timestamp,'localtime')>=date('now','-7 days','localtime')"),
                (t.days30,    "calendar.badge.clock", "date(timestamp,'localtime')>=date('now','-30 days','localtime')"),
                (t.allTime,   "infinity",             "1=1"),
            ]
            var result: [(String, String, Double, Int64)] = []
            for (lbl, ico, w) in defs {
                let mr = dbRun("""
                    SELECT COALESCE(model,'unknown'), COALESCE(SUM(input_tokens),0), COALESCE(SUM(output_tokens),0),
                           COALESCE(SUM(cache_read_tokens),0), COALESCE(SUM(cache_creation_tokens),0)
                    FROM turns WHERE \(w) GROUP BY model
                """)
                let cost = mr.reduce(0.0) { $0 + costOf(inp: i64($1,1), out: i64($1,2), cr: i64($1,3), cw: i64($1,4), m: str($1,0)) }
                let tokens = mr.reduce(Int64(0)) { $0 + i64($1,1) + i64($1,2) + i64($1,3) + i64($1,4) }
                result.append((lbl, ico, cost, tokens))
            }
            DispatchQueue.main.async { data = result }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Section Header
// ═══════════════════════════════════════════════════════════════

struct LimitBar: View {
    let label: String; let pct: Double; let resets: String

    var barColor: Color {
        if pct < 0.5 { return .green }
        if pct < 0.8 { return .yellow }
        return .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.system(size: 9, weight: .medium)).foregroundColor(.secondary)
                Circle().fill(barColor).frame(width: 5, height: 5)
                Spacer()
                Text("\(Int(pct * 100))%").font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(barColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(barColor)
                        .frame(width: max(2, geo.size.width * CGFloat(min(pct, 1.0))))
                }
            }.frame(height: 5)
            Text(resets.isEmpty ? " " : "Resets in \(resets)")
                .font(.system(size: 8)).foregroundColor(.secondary.opacity(0.6))
        }
    }
}

struct SectionHead: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(.secondary)
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Main Popover View
// ═══════════════════════════════════════════════════════════════

struct PopoverView: View {
    @ObservedObject var vm: VM
    @ObservedObject var loc = i18n
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // ── Header ──
                header.padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 6)
                Divider()

                // ── Content ──
                ScrollView(.vertical, showsIndicators: !expanded) {
                    VStack(alignment: .leading, spacing: 10) {
                        QuickPeriods().id(loc.lang)
                        Divider()
                        SummaryCards(s: vm.summary)
                        DailyChart(data: vm.daily)
                        HStack(alignment: .top, spacing: 16) {
                            ModelDonut(models: vm.models).frame(maxWidth: .infinity)
                            ProjectsList(projects: vm.projects).frame(maxWidth: .infinity)
                        }
                        CostTable(models: vm.models)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .id(loc.lang)
                }

                Divider()

                // ── Footer ──
                footer.padding(.horizontal, 14).padding(.vertical, 6)
            }
            .frame(width: 520, height: expanded ? 880 : 500)
            .background(Color(nsColor: NSColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer(minLength: 0)
        }
        .frame(width: 520, height: 880, alignment: .top)
        .animation(.easeInOut(duration: 0.3), value: expanded)
        .preferredColorScheme(.dark)
    }

    // ── Header ──────────────────────────────────────────

    var header: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundStyle(.linearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("Claude Usage")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text(vm.limits.plan)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.purple.opacity(0.3))
                    .cornerRadius(6)
                Picker("", selection: $vm.period) {
                    ForEach(Period.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(width: 110)
            }

            // Session & Weekly limit bars
            HStack(spacing: 12) {
                LimitBar(label: t.session5h, pct: vm.limits.sessionPct, resets: vm.limits.sessionReset)
                LimitBar(label: t.weekly,   pct: vm.limits.weeklyPct,  resets: vm.limits.weeklyReset)
            }
        }
    }

    // ── Footer ──────────────────────────────────────────

    var footer: some View {
        HStack(spacing: 8) {
            if vm.scanning {
                ProgressView().controlSize(.small)
                Text(t.scanning).font(.caption2).foregroundColor(.secondary)
            } else {
                Text("\(t.updateIn) \(vm.countdown)s").font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 10) {
                Button(action: { vm.scanAndReload() }) {
                    Image(systemName: "arrow.clockwise").frame(width: 14, height: 14)
                }.buttonStyle(.borderless).disabled(vm.scanning).help(t.refresh)

                Menu {
                    ForEach(Lang.allCases) { lang in
                        Button("\(lang.flag) \(lang.label)") {
                            i18n.lang = lang.rawValue
                        }
                    }
                } label: {
                    Image(systemName: "globe").frame(width: 14, height: 14)
                }.menuStyle(.borderlessButton).fixedSize()

                Button(action: { expanded.toggle() }) {
                    Image(systemName: expanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                        .frame(width: 14, height: 14)
                }.buttonStyle(.borderless).help(expanded ? "Compact" : "Details")

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "power").frame(width: 14, height: 14)
                }.buttonStyle(.borderless).help(t.quit)
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - App Delegate
// ═══════════════════════════════════════════════════════════════

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var panel: NSPanel!
    var vm: VM!
    var monitor: Any?
    var hostingController: NSHostingController<PopoverView>!

    func applicationDidFinishLaunching(_ n: Notification) {
        vm = VM()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button {
            btn.image = createBarImage(sPct: vm.limits.sessionPct, wPct: vm.limits.weeklyPct)
            btn.imagePosition = .imageLeading
            btn.action = #selector(toggle)
            btn.target = self
            updateStatusTitle(btn)
        }

        vm.onUpdate = { [weak self] in
            guard let self = self, let btn = self.statusItem.button else { return }
            self.updateBarIcon()
            self.updateStatusTitle(btn)
        }

        let panelW: CGFloat = 520
        let panelH: CGFloat = 880

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelW, height: panelH),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: true)
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hidesOnDeactivate = false

        let hc = NSHostingController(rootView: PopoverView(vm: vm))
        hc.preferredContentSize = NSSize(width: panelW, height: panelH)
        hc.view.setFrameSize(NSSize(width: panelW, height: panelH))
        hc.view.autoresizingMask = [.width, .height]
        hc.view.appearance = NSAppearance(named: .darkAqua)
        hc.view.wantsLayer = true
        hc.view.layer?.cornerRadius = 12
        hc.view.layer?.masksToBounds = true
        panel.contentViewController = hc
        self.hostingController = hc

        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] _ in
            if self?.panel.isVisible == true {
                self?.panel.orderOut(nil)
                self?.panelActive = false
                self?.updateBarIcon()
                if let btn = self?.statusItem.button { self?.updateStatusTitle(btn) }
            }
        }

        vm.scanAndReload()
    }

    var panelActive = false

    func updateBarIcon() {
        guard let btn = statusItem.button else { return }
        btn.image = createBarImage(
            sPct: vm.limits.sessionPct,
            wPct: vm.limits.weeklyPct,
            active: panelActive
        )
    }

    func updateStatusTitle(_ btn: NSStatusBarButton) {
        let plan = vm.limits.plan
        let cost = fC(vm.todayCost)
        let str = NSMutableAttributedString()
        str.append(NSAttributedString(string: " \(plan) ", attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: panelActive ? NSColor.systemGreen.withAlphaComponent(0.9) : NSColor.secondaryLabelColor
        ]))
        str.append(NSAttributedString(string: "│ ", attributes: [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: panelActive ? NSColor.systemGreen.withAlphaComponent(0.5) : NSColor.tertiaryLabelColor
        ]))
        str.append(NSAttributedString(string: cost, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .bold),
            .foregroundColor: panelActive ? NSColor.systemGreen : NSColor.white
        ]))
        btn.attributedTitle = str
    }

    @objc func toggle() {
        guard let btn = statusItem.button else { return }
        if panel.isVisible {
            panel.orderOut(nil)
            panelActive = false
            updateBarIcon()
            updateStatusTitle(btn)
            return
        }
        guard let btnWindow = btn.window else { return }
        let btnRect = btn.convert(btn.bounds, to: nil)
        let screenRect = btnWindow.convertToScreen(btnRect)

        let pw = panel.frame.width
        let ph = panel.frame.height
        var x = screenRect.maxX - pw
        let y = screenRect.minY - ph - 4

        if let screen = NSScreen.main {
            x = max(screen.visibleFrame.origin.x, x)
        }

        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.makeKeyAndOrderFront(nil)
        panelActive = true
        updateBarIcon()
        updateStatusTitle(btn)
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Entry Point
// ═══════════════════════════════════════════════════════════════

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
