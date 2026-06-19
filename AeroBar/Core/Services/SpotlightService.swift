// SpotlightService.swift — Indexes all installed apps via NSMetadataQuery.
// Owner: Core/Services
// Depends on: AppKit, Foundation
//
// Call start() once from AppDelegate. Results land in AeroBarSettings.indexedLocalApps.
// The query runs on a background thread; UI updates are dispatched to main.

import AppKit
import Foundation

final class SpotlightService {
    static let shared = SpotlightService()
    private init() {}

    private var query: NSMetadataQuery?

    func start() {
        let q = NSMetadataQuery()
        query = q
        q.searchScopes = [NSMetadataQueryLocalComputerScope]
        q.predicate = NSPredicate(format: "kMDItemContentType == 'com.apple.application-bundle'")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleResults),
            name: .NSMetadataQueryDidFinishGathering,
            object: q
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleResults),
            name: .NSMetadataQueryDidUpdate,
            object: q
        )
        q.start()
    }

    @objc private func handleResults(notification: Notification) {
        guard let q = notification.object as? NSMetadataQuery else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            var apps: [DiscoverableApp] = []

            // Finder isn't in the normal query scope — pin it first.
            let finderPath = "/System/Library/CoreServices/Finder.app"
            if FileManager.default.fileExists(atPath: finderPath) {
                apps.append(DiscoverableApp(
                    appName: "Finder",
                    path: finderPath,
                    icon: NSWorkspace.shared.icon(forFile: finderPath)
                ))
            }

            q.disableUpdates()
            for i in 0..<q.resultCount {
                guard let item = q.result(at: i) as? NSMetadataItem,
                      let path = item.value(forAttribute: NSMetadataItemPathKey) as? String,
                      let name = item.value(forAttribute: NSMetadataItemDisplayNameKey) as? String
                else { continue }

                if apps.contains(where: { $0.path == path }) { continue }
                if path.contains("/Contents/Frameworks/") { continue }

                apps.append(DiscoverableApp(appName: name, path: path, icon: NSWorkspace.shared.icon(forFile: path)))
            }
            q.enableUpdates()

            let sorted = apps.sorted { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
            DispatchQueue.main.async { AeroBarSettings.shared.indexedLocalApps = sorted }
        }
    }
}
