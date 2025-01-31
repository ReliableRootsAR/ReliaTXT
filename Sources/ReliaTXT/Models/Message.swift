import Foundation

struct Message: Identifiable, Equatable {
    let id: String
    let ticketId: String
    let senderId: String
    let senderType: SenderType
    let content: String
    let timestamp: Date
    var isRead: Bool
    var attachmentURL: String?
    
    enum SenderType: String, Codable {
        case locator
        case customer
        case system
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.ticketId == rhs.ticketId &&
        lhs.senderId == rhs.senderId &&
        lhs.senderType == rhs.senderType &&
        lhs.content == rhs.content &&
        lhs.timestamp == rhs.timestamp &&
        lhs.isRead == rhs.isRead &&
        lhs.attachmentURL == rhs.attachmentURL
    }
}
