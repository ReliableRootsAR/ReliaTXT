import SwiftUI
import FirebaseAuth

struct TicketListView: View {
    @StateObject private var viewModel = TicketViewModel()
    @State private var searchText = ""
    @State private var selectedStatus: Ticket.TicketStatus = .active
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private var filteredTickets: [Ticket] {
        viewModel.tickets.filter { ticket in
            searchText.isEmpty ||
                ticket.customerName.localizedCaseInsensitiveContains(searchText) ||
                ticket.address.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with status filter
            VStack(spacing: 16) {
                HStack {
                    Text("Tickets")
                        .font(.title)
                        .bold()
                    Spacer()
                }
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach([Ticket.TicketStatus.active, .closed], id: \.rawValue) { status in
                            filterButton(status)
                        }
                    }
                    .padding(.horizontal)
                }
                
                searchBar
            }
            .padding(.top)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            ticketList
        }
        .onAppear {
            loadTickets()
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search tickets...", text: $searchText)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var ticketList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredTickets.isEmpty {
                emptyStateView
            } else {
                List(filteredTickets) { ticket in
                    NavigationLink(destination: ChatView(ticket: ticket)
                        .environmentObject(authViewModel)) {  // Add this line
                        TicketRowView(ticket: ticket)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .listStyle(.plain)
                .refreshable {
                    loadTickets()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "ticket")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No \(selectedStatus.rawValue) tickets found")
                .font(.title2)
                .bold()
            Text(searchText.isEmpty ? "New tickets will appear here" : "Try adjusting your search")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadTickets() {
        if let user = authViewModel.user {
            viewModel.loadTickets(for: user.id, status: selectedStatus)
        }
    }
    
    private func filterButton(_ status: Ticket.TicketStatus) -> some View {
        Button(action: {
            selectedStatus = status
            loadTickets()
        }) {
            Text(status.rawValue.capitalized)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedStatus == status ? Color.blue : Color(.systemGray6))
                .foregroundColor(selectedStatus == status ? .white : .primary)
                .cornerRadius(20)
        }
    }
}
