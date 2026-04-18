import Foundation
import SwiftData

@Model
final class ChecklistItem {
    var text: String
    var statusRaw: String = ItemStatus.incomplete.rawValue
    var order: Int = 0
    var tags: [Tag] = []
    var checklist: Checklist?

    var status: ItemStatus {
        get { ItemStatus(rawValue: statusRaw) ?? .incomplete }
        set { statusRaw = newValue.rawValue }
    }

    init(text: String, order: Int = 0) {
        self.text = text
        self.order = order
    }
}
