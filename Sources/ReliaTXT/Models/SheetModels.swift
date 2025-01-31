import Foundation

struct SheetTicket: Codable {
    let ticketNumber: String
    let dueDate: Date
    let customer: String
    let phoneNumber: String
    let assignedTo: String  // Format: "LastName, FirstName"
    
    // Convert to Firestore Ticket
    func toFirestoreTicket() -> [String: Any] {
        let names = assignedTo.split(separator: ",").map(String.init)
        let lastName = names[0].trimmingCharacters(in: .whitespaces)
        let firstName = names.count > 1 ? names[1].trimmingCharacters(in: .whitespaces) : ""
        
        return [
            "id": ticketNumber,
            "customerName": customer,
            "contactPhone": phoneNumber,
            "status": "active",
            "type": "standard",
            "createdAt": Date(),
            "assignedLocator": "\(firstName) \(lastName)",
            "dueDate": dueDate,
            "address": ""  // You might want to add this to your sheet
        ]
    }
}
