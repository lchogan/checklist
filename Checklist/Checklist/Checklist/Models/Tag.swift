import Foundation
import SwiftData

@Model
final class Tag {
    var name: String
    var iconName: String = "tag"
    var items: [ChecklistItem] = []

    init(name: String, iconName: String = "tag") {
        self.name = name
        self.iconName = iconName
    }

    /// Number of distinct checklists that have at least one item tagged with this tag.
    var checklistCount: Int {
        Set(items.compactMap { $0.checklist?.persistentModelID }).count
    }
}
