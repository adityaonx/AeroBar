// RecycleBinButton.swift — Trash shortcut at the right end of the bar.
// Owner: Views/Subviews
// Depends on: AppKit

import SwiftUI
import AppKit

struct RecycleBinButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image("s-trashfull")
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .padding(4)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .help("Recycle Bin")
        .contextMenu {
            Button(role: .destructive) {
                emptyTrash()
            } label: {
                Label("Empty Trash Bin", systemImage: "trash.slash")
            }
        }
    }
    
    // Empties the Trash via Finder's AppleScript dictionary — the same operation
    // as choosing Finder > Empty Trash, just triggered from the bar.
    private func emptyTrash() {
        DispatchQueue.global(qos: .userInitiated).async {
            let scriptSource = """
            tell application "Finder"
                empty trash
            end tell
            """
            if let appleScript = NSAppleScript(source: scriptSource) {
                var errorDict: NSDictionary?
                appleScript.executeAndReturnError(&errorDict)
                if let err = errorDict {
                    print("AeroBar RecycleBinButton: Empty Trash failed — \(err)")
                }
            }
        }
    }
}
