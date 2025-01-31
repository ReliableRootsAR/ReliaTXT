import SwiftUI
import FirebaseFirestore

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var errorMessage: String?
    @Published var isEnRoute = false
    
    private var listener: ListenerRegistration?
    private let firebaseService = FirebaseService.shared
    
    func subscribe(to ticketId: String) {
        listener = firebaseService.subscribeToMessages(ticketId: ticketId) { [weak self] messages in
            DispatchQueue.main.async {
                self?.messages = messages.sorted(by: { $0.timestamp < $1.timestamp })
            }
        }
    }
    
    func unsubscribe() {
        listener?.remove()
    }
    
    func sendMessage(text: String, ticketId: String, sender: String) {
        Task {
            do {
                let message = Message(
                    id: UUID().uuidString,
                    ticketId: ticketId,
                    senderId: sender,
                    senderType: .locator,
                    content: text,
                    timestamp: Date(),
                    isRead: false,
                    attachmentURL: nil
                )
                
                try await firebaseService.sendMessage(message)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func closeChat(ticket: Ticket) async throws {
        var updatedTicket = ticket
        updatedTicket.status = .closed
        updatedTicket.closedAt = Date()
        try await firebaseService.updateTicket(updatedTicket)
    }
    
    func updateEnRouteStatus(ticket: Ticket, isEnRoute: Bool) async throws {
        var updatedTicket = ticket
        updatedTicket.isEnRoute = isEnRoute
        try await firebaseService.updateTicket(updatedTicket)
    }
    
    deinit {
        unsubscribe()
    }
}
