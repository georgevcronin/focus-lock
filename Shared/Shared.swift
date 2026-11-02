import FamilyControls
import ManagedSettings
import DeviceActivity

let groupID = "group.com.georgevcronin.focuslock"
let defaults = UserDefaults(suiteName: groupID)!
let store = ManagedSettingsStore()

struct Slot: Codable, Identifiable, Hashable {
    var id = UUID()
    var weekday: Int  // Calendar weekday: 1 = Sunday ... 7 = Saturday
    var start: Int    // minutes since midnight
    var end: Int      // must be > start (no windows across midnight)
}

func loadSelection() -> FamilyActivitySelection {
    defaults.data(forKey: "sel").flatMap { try? JSONDecoder().decode(FamilyActivitySelection.self, from: $0) } ?? .init()
}
func loadSlots() -> [Slot] {
    defaults.data(forKey: "win").flatMap { try? JSONDecoder().decode([Slot].self, from: $0) } ?? []
}
func save(_ sel: FamilyActivitySelection, _ wins: [Slot]) {
    defaults.set(try? JSONEncoder().encode(sel), forKey: "sel")
    defaults.set(try? JSONEncoder().encode(wins), forKey: "win")
}

func shield() {
    let s = loadSelection()
    store.shield.applications = s.applicationTokens
    store.shield.applicationCategories = .specific(s.categoryTokens)
    store.shield.webDomains = s.webDomainTokens
}
func lift() { store.clearAllSettings() }

func isAllowed(at date: Date = .now) -> Bool {
    let c = Calendar.current.dateComponents([.weekday, .hour, .minute], from: date)
    let m = c.hour! * 60 + c.minute!
    return loadSlots().contains { $0.weekday == c.weekday! && $0.start <= m && m < $0.end }
}

/// Settings are editable inside a window, or on first run before any window exists (else setup would be impossible).
func isOpen() -> Bool { loadWindows().isEmpty || isAllowed() }

/// Locked unless inside a window. Also (re)registers the weekly schedules that flip it later.
func apply() {
    let center = DeviceActivityCenter()
    center.stopMonitoring()
    for w in loadSlots() {
        let start = DateComponents(hour: w.start / 60, minute: w.start % 60, weekday: w.weekday)
        let end = DateComponents(hour: w.end / 60, minute: w.end % 60, weekday: w.weekday)
        // ponytail: iOS caps monitored activities (~20), so ~20 windows/week total; merge windows if more are needed
        try? center.startMonitoring(DeviceActivityName(w.id.uuidString),
                                    during: DeviceActivitySchedule(intervalStart: start, intervalEnd: end, repeats: true))
    }
    isAllowed() ? lift() : shield()
}
