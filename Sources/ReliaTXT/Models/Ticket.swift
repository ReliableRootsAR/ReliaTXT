import Foundation
import FirebaseFirestore

struct Ticket: Identifiable {
    let id: String
    var customerName: String
    var address: String
    var status: TicketStatus
    var type: TicketType
    var createdAt: Date
    var closedAt: Date?
    var locatorId: String
    var contactPhone: String?
    var contactEmail: String?
    var notes: String?
    var assignedLocator: String?
    var dueDate: Date?
    var isEnRoute: Bool = false
    
    enum TicketStatus: String, Codable {
        case active
        case closed
        case archived
        
        var displayName: String {
            switch self {
            case .active: return "Active"
            case .closed: return "Closed"
            case .archived: return "Archived"
            }
        }
    }
    
    enum TicketType: String, Codable {
        case emergency
        case standard
        
        var displayName: String {
            switch self {
            case .emergency: return "Emergency"
            case .standard: return "Standard"
            }
        }
    }
    
    var isArchived: Bool {
        guard let closedAt = closedAt else { return false }
        return Calendar.current.dateComponents([.day], from: closedAt, to: Date()).day ?? 0 > 21
    }
}

// Add Firestore conversion methods
extension Ticket {
    static func fromFirestore(_ data: [String: Any], id: String) -> Ticket? {
        print("Starting to parse ticket with ID: \(id)")
        print("Raw data: \(data)")
        
        // Required fields with default values if missing
        let customerName = data["customerName"] as? String ?? "Unknown Customer"
        let address = data["address"] as? String ?? "Unknown"
        let statusRaw = data["status"] as? String ?? "active"
        let typeRaw = data["type"] as? String ?? "standard"
        let locatorId = data["assignedLocator"] as? String ?? ""
        
        // Validate enums
        guard let status = TicketStatus(rawValue: statusRaw) else {
            print("❌ Invalid status value: \(statusRaw) for ticket \(id)")
            return nil
        }
        
        guard let type = TicketType(rawValue: typeRaw) else {
            print("❌ Invalid type value: \(typeRaw) for ticket \(id)")
            return nil
        }
        
        // Optional fields
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let closedAt = (data["closedAt"] as? Timestamp)?.dateValue()
        let dueDate = (data["dueDate"] as? Timestamp)?.dateValue()
        let isEnRoute = data["isEnRoute"] as? Bool ?? false
        
        print("✅ Successfully parsed ticket \(id)")
        print("Status: \(status.rawValue)")
        print("Type: \(type.rawValue)")
        print("Customer: \(customerName)")
        
        return Ticket(
            id: id,
            customerName: customerName,
            address: address,
            status: status,
            type: type,
            createdAt: createdAt,
            closedAt: closedAt,
            locatorId: locatorId,
            contactPhone: data["contactPhone"] as? String,
            contactEmail: data["contactEmail"] as? String,
            notes: data["notes"] as? String,
            assignedLocator: data["assignedLocator"] as? String,
            dueDate: dueDate,
            isEnRoute: isEnRoute
        )
    }
    
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "customerName": customerName,
            "address": address,
            "status": status.rawValue,
            "type": type.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "assignedLocator": locatorId,
            "isEnRoute": isEnRoute
        ]
        
        if let closedAt = closedAt {
            data["closedAt"] = Timestamp(date: closedAt)
        }
        if let contactPhone = contactPhone {
            data["contactPhone"] = contactPhone
        }
        if let contactEmail = contactEmail {
            data["contactEmail"] = contactEmail
        }
        if let notes = notes {
            data["notes"] = notes
        }
        if let assignedLocator = assignedLocator {
            data["assignedLocator"] = assignedLocator
        }
        if let dueDate = dueDate {
            data["dueDate"] = Timestamp(date: dueDate)
        }
        
        return data
    }
}
