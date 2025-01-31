import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    enum FirebaseError: Error {
        case userNotFound
        case invalidData
        case missingTicketID
        case dataSerializationError
    }
    
    // MARK: - User Functions
    
    func createUser(_ user: User) async throws {
        var data: [String: Any] = [
            "email": user.email,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "fullName": "\(user.lastName), \(user.firstName)",
            "role": user.role.rawValue,
            "isActive": user.isActive,
            "createdAt": Timestamp(date: user.createdAt)
        ]
        
        if let phone = user.phone {
            data["phone"] = phone
        }
        
        if let deviceToken = user.deviceToken {
            data["deviceToken"] = deviceToken
        }
        
        try await db.collection("users").document(user.id).setData(data)
    }
    
    func updateUser(_ user: User) async throws {
        var data: [String: Any] = [
            "email": user.email,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "fullName": "\(user.lastName), \(user.firstName)",
            "role": user.role.rawValue,
            "isActive": user.isActive
        ]
        
        if let phone = user.phone {
            data["phone"] = phone
        }
        
        if let deviceToken = user.deviceToken {
            data["deviceToken"] = deviceToken
        }
        
        try await db.collection("users").document(user.id).setData(data, merge: true)
    }
    
    func getUser(id: String?) async throws -> User? {
        guard let userId = id else {
            print("User ID is nil")
            return nil
        }
        
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard document.exists, let data = document.data() else {
            print("User not found or data is invalid")
            return nil
        }
        
        let email = data["email"] as? String ?? ""
        let firstName = data["firstName"] as? String ?? ""
        let lastName = data["lastName"] as? String ?? ""
        let roleString = data["role"] as? String ?? "customer"
        let role = User.UserRole(rawValue: roleString) ?? .customer
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        
        return User(
            id: document.documentID,
            email: email,
            firstName: firstName,
            lastName: lastName,
            role: role,
            phone: data["phone"] as? String,
            isActive: data["isActive"] as? Bool ?? true,
            deviceToken: data["deviceToken"] as? String,
            createdAt: createdAt
        )
    }
    
    // MARK: - Ticket Functions
    
    // MARK: - Ticket Functions
        
    func getAllTickets(for locatorId: String?, status: Ticket.TicketStatus? = nil) async throws -> [Ticket] {
        guard let locatorId = locatorId else {
            print("Locator ID is nil")
            return []
        }
        
        guard let user = try await getUser(id: locatorId) else {
            print("No user found for locator ID: \(locatorId)")
            return []
        }
        
        // Format name correctly
        let formattedName = "\(user.lastName), \(user.firstName)"
        print("Searching for tickets with assigned locator: \(formattedName)")
        
        // Start with base query
        var query: Query = db.collection("tickets")
            .whereField("assignedLocator", isEqualTo: formattedName)
        
        // Add status filter if provided
        if let status = status {
            query = query.whereField("status", isEqualTo: status.rawValue)
        }
        
        // Don't add sorting initially to see if we can get the data
        do {
            let snapshot = try await query.getDocuments()
            print("Found \(snapshot.documents.count) tickets")
            
            var tickets = snapshot.documents.compactMap { document -> Ticket? in
                let data = document.data()
                return Ticket.fromFirestore(data, id: document.documentID)
            }
            
            // Sort in memory instead of in query
            tickets.sort { ($0.createdAt) > ($1.createdAt) }
            
            print("Successfully parsed \(tickets.count) tickets")
            return tickets
            
        } catch {
            print("Error fetching tickets: \(error.localizedDescription)")
            throw error
        }
    }

    func getTicketsByStatus(for locatorId: String?, status: Ticket.TicketStatus) async throws -> [Ticket] {
        guard let locatorId = locatorId else {
            print("Locator ID is nil")
            return []
        }
        
        guard let user = try await getUser(id: locatorId) else {
            print("No user found for locator ID: \(locatorId)")
            return []
        }
        
        let formattedName = "\(user.lastName), \(user.firstName)"
        print("Searching for \(status.rawValue) tickets with assigned locator: \(formattedName)")
        
        let query = db.collection("tickets")
            .whereField("assignedLocator", isEqualTo: formattedName)
            .whereField("status", isEqualTo: status.rawValue)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { document -> Ticket? in
            let data = document.data()
            return Ticket.fromFirestore(data, id: document.documentID)
        }
    }
    
    func updateTicket(_ ticket: Ticket) async throws {
        print("Updating ticket: \(ticket.id)")
        let data = ticket.toFirestore()
        print("Update data: \(data)")
        try await db.collection("tickets").document(ticket.id).setData(data, merge: true)
    }
    
    // MARK: - Message Functions
        
    func sendMessage(_ message: Message) async throws {
        let data: [String: Any] = [
            "ticketId": message.ticketId,
            "senderId": message.senderId,
            "senderType": message.senderType.rawValue,
            "content": message.content,
            "timestamp": Timestamp(date: message.timestamp),
            "isRead": message.isRead
        ]
        
        try await db.collection("messages").addDocument(data: data)
    }

    func subscribeToMessages(ticketId: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        print("Subscribing to messages for ticket: \(ticketId)")
        
        let query = db.collection("messages")
            .whereField("ticketId", isEqualTo: ticketId)
            .order(by: "timestamp", descending: false)
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching messages: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found")
                completion([])
                return
            }
            
            print("Found \(documents.count) messages")
            
            let messages: [Message] = documents.compactMap { document -> Message? in
                let data = document.data()
                print("Processing message data: \(data)")
                
                // Parse data matching exact field names from Firestore
                guard let ticketId = data["ticketId"] as? String,
                      let senderId = data["senderId"] as? String,
                      let senderTypeRaw = data["senderType"] as? String,
                      let content = data["content"] as? String,
                      let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
                    print("Failed to parse required fields for message: \(document.documentID)")
                    return nil
                }
                
                let isRead = data["isRead"] as? Bool ?? false
                let senderType = Message.SenderType(rawValue: senderTypeRaw) ?? .system
                
                return Message(
                    id: document.documentID,
                    ticketId: ticketId,
                    senderId: senderId,
                    senderType: senderType,
                    content: content,
                    timestamp: timestamp,
                    isRead: isRead,
                    attachmentURL: data["attachmentURL"] as? String
                )
            }
            
            completion(messages)
        }
    }
    
    // MARK: - Storage Functions
    
    func uploadImage(_ image: UIImage, forTicket ticketId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            throw FirebaseError.invalidData
        }
        
        let filename = "\(UUID().uuidString).jpg"
        let path = "tickets/\(ticketId)/\(filename)"
        let storageRef = Storage.storage().reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
}
