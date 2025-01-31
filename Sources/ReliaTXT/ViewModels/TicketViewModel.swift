import SwiftUI
import FirebaseAuth

class TicketViewModel: ObservableObject {
    @Published var tickets: [Ticket] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let firebaseService = FirebaseService.shared
    
    func loadTickets(for locatorId: String, status: Ticket.TicketStatus? = nil) {
        isLoading = true
        tickets = [] // Clear existing tickets before loading new ones
        
        Task {
            do {
                let fetchedTickets = try await firebaseService.getAllTickets(for: locatorId, status: status)
                DispatchQueue.main.async {
                    self.tickets = fetchedTickets
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    func updateTicketStatus(_ ticket: Ticket, to status: Ticket.TicketStatus) async throws {
        var updatedTicket = ticket
        updatedTicket.status = status
        
        if status == .closed {
            updatedTicket.closedAt = Date()
        }
        
        try await firebaseService.updateTicket(updatedTicket)
        
        // Refresh the tickets list after updating
        if let userId = Auth.auth().currentUser?.uid {
            loadTickets(for: userId, status: status)
        }
    }
}
