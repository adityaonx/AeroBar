import Foundation

enum DisplayTargetMode: String, CaseIterable, Identifiable {
    case all = "All Displays"
    case primaryOnly = "Main Screen Only"
    case secondaryOnly = "External Displays Only"
    
    var id: String { self.rawValue }
}
