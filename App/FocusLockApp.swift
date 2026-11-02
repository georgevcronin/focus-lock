import SwiftUI
import FamilyControls

@main
struct FocusLockApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var sel = loadSelection()
    @State private var windows = loadWindows()
    @State private var picking = false
    @State private var error = ""
    @State private var open = isOpen()
    private let tick = Timer.publish(every: 20, on: .main, in: .common).autoconnect()

    var valid: Bool { windows.allSatisfy { $0.end > $0.start } && windows.count <= 20 }

    var body: some View {
        NavigationStack {
            Form {
                if !unlocked {
                    Section { Text("Locked. Settings can only be changed during an allowed window.").foregroundStyle(.orange) }
                }
                Section {
                    Button("Choose apps & sites to block") { picking = true }
                    Text("\(sel.applicationTokens.count) apps · \(sel.categoryTokens.count) categories · \(sel.webDomainTokens.count) sites")
                        .foregroundStyle(.secondary)
                }
                ForEach(1...7, id: \.self) { day in
                    Section(Calendar.current.weekdaySymbols[day - 1]) {
                        ForEach($windows) { $w in
                            if w.weekday == day {
                                HStack {
                                    DatePicker("", selection: time($w.start), displayedComponents: .hourAndMinute)
                                    Text("to")
                                    DatePicker("", selection: time($w.end), displayedComponents: .hourAndMinute)
                                    Button(role: .destructive) { windows.removeAll { $0.id == w.id } } label: { Image(systemName: "trash") }
                                        .buttonStyle(.borderless)
                                }
                            }
                        }
                        Button("Add allowed window") { windows.append(Slot(weekday: day, start: 720, end: 780)) }
                    }
                }
                Section {
                    Button("Save & lock") {
                        guard isOpen() else { unlocked = false; return }
                        save(sel, windows)
                        apply()
                    }.disabled(!valid)
                    if !valid { Text("Each window must end after it starts; max 20 windows.").foregroundStyle(.red) }
                    if !error.isEmpty { Text(error).foregroundStyle(.red) }
                }
            }
            .disabled(!unlocked)
            .onReceive(tick) { _ in unlocked = isOpen() }
            .navigationTitle("Focus Lock")
            .familyActivityPicker(isPresented: $picking, selection: $sel)
            .task {
                do { try await AuthorizationCenter.shared.requestAuthorization(for: .individual) }
                catch { self.error = "Screen Time access denied: \(error.localizedDescription)" }
                apply()
            }
        }
    }

    private func time(_ m: Binding<Int>) -> Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: m.wrappedValue / 60, minute: m.wrappedValue % 60, second: 0, of: .now)! },
            set: { let c = Calendar.current.dateComponents([.hour, .minute], from: $0); m.wrappedValue = c.hour! * 60 + c.minute! })
    }
}
