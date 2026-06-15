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
        // 🎯 FIXED: Right-click menu triggers automated background Empty Trash cycle
        .contextMenu {
            Button(role: .destructive) {
                executeNativeEmptyTrashWorkflow()
            } label: {
                Label("Empty Trash Bin", systemImage: "trash.slash")
            }
        }
    }
    
    // MARK: - 🗑️ Empty Trash Operation Automation
    private func executeNativeEmptyTrashWorkflow() {
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
                    print("AeroBar Empty Trash Script Error: \(err)")
                }
            }
        }
    }
}
