// PinnedAppsService.swift — Loads and saves the pinned-apps lists to UserDefaults.
// Owner: Core/Services
// Depends on: Foundation, Core/Models/PinnedApp
// Tested by: Tests/PinnedAppsServiceTests.swift
//
// This is intentionally a plain class with no SwiftUI dependency so it can be
// unit-tested without an app context.

import Foundation

final class PinnedAppsService {
    static let shared = PinnedAppsService()
    private init() {}

    private let startKey = "com.aerobar.pinnedStartApplicationsOrder"
    private let barKey   = "com.aerobar.pinnedBarApplicationsOrder"

    struct LoadedPins {
        var start: [PinnedApp]
        var bar: [PinnedApp]
    }

    func load() -> LoadedPins {
        LoadedPins(
            start: decode(key: startKey),
            bar: decode(key: barKey)
        )
    }

    func savePinnedStart(_ apps: [PinnedApp]) {
        encode(apps, key: startKey)
    }

    func savePinnedBar(_ apps: [PinnedApp]) {
        encode(apps, key: barKey)
    }

    // Finder must always be pinned as a non-removable anchor in both lists.
    func ensureFinderPinned(start: inout [PinnedApp], bar: inout [PinnedApp]) {
        let finder = PinnedApp(bundleIdentifier: "com.apple.finder", appName: "Finder")
        if !start.contains(where: { $0.bundleIdentifier == finder.bundleIdentifier }) {
            start.insert(finder, at: 0)
        }
        if !bar.contains(where: { $0.bundleIdentifier == finder.bundleIdentifier }) {
            bar.insert(finder, at: 0)
        }
    }

    // MARK: - Private

    private func decode(key: String) -> [PinnedApp] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let apps = try? JSONDecoder().decode([PinnedApp].self, from: data)
        else { return [] }
        return apps
    }

    private func encode(_ apps: [PinnedApp], key: String) {
        guard let data = try? JSONEncoder().encode(apps) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
