import SwiftUI
import FirebaseAuth

struct ChatView: View {
    let ticket: Ticket
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingCloseAlert = false
    
    private var defaultMessage: String {
        guard let user = authViewModel.user else { return "" }
        return "Hello! This is \(user.firstName) from Reliable Roots Locating. I'm on my way to your location and should arrive in approximately 15 minutes."
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header
            chatHeader
                .background(Color(.systemBackground))
                .shadow(radius: 1)
            
            // Messages
            messageList
            
            // Message input
            if !ticket.isArchived {
                messageInput
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            viewModel.subscribe(to: ticket.id)
        }
        .onDisappear {
            viewModel.unsubscribe()
        }
        .alert("Close Chat", isPresented: $showingCloseAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Close", role: .destructive) {
                Task {
                    try? await viewModel.closeChat(ticket: ticket)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to close this chat?")
        }
    }
    
    private var chatHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Secure Channel - LOC-\(String(format: "%04d", Int(ticket.id) ?? 0))")
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
                
                if ticket.status == .active {
                    Button("Close Chat") {
                        showingCloseAlert = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if ticket.type == .emergency {
                Label("Emergency Contact: \(ticket.contactPhone ?? "N/A")", systemImage: "phone.fill")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.vertical)
            }
            .onChange(of: viewModel.messages) { messages in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id)
                    }
                }
            }
        }
    }
    
    private var messageInput: some View {
        HStack {
            Button(action: {
                messageText = defaultMessage
            }) {
                Image(systemName: "text.quote")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 8)
            
            TextField("Message", text: $messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button {
                if !messageText.isEmpty {
                    print("Attempting to send message: \(messageText)")
                    Task {
                        do {
                            try await viewModel.sendMessage(
                                text: messageText,
                                ticketId: ticket.id,
                                sender: authViewModel.user?.id ?? ""
                            )
                            print("Message sent successfully")
                            messageText = ""
                        } catch {
                            print("Error sending message: \(error.localizedDescription)")
                        }
                    }
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
