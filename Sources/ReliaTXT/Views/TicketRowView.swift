import SwiftUI

struct TicketRowView: View {
    let ticket: Ticket
    @State private var isEnRoute = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LOC-\(String(format: "%04d", Int.random(in: 1...9999)))")
                        .font(.headline)
                    
                    Text(ticket.customerName)
                        .font(.subheadline)
                    
                    if let dueDate = ticket.dueDate {
                        Text(formatDate(dueDate))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                statusBadge
            }
            
            HStack {
                if ticket.type == .emergency {
                    Label("Emergency", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                if ticket.status == .active && isEnRoute {
                    Button(action: { isEnRoute.toggle() }) {
                        Label("En Route", systemImage: "car.fill")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var statusBadge: some View {
        Text(ticket.status.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch ticket.status {
        case .active:
            return .green
        case .closed:
            return .gray
        case .archived:
            return .red
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
