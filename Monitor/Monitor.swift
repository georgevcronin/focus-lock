import DeviceActivity

class Monitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) { lift() }
    override func intervalDidEnd(for activity: DeviceActivityName) {
        // stay open if another window starts right as this one ends
        if !isAllowed(at: Date().addingTimeInterval(30)) { shield() }
    }
}
