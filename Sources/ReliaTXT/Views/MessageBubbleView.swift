import SwiftUI
import SDWebImageSwiftUI

struct MessageBubbleView: View {
    let message: Message
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var imageLoaded = false
    
    private var isFromCurrentUser: Bool {
        message.senderId == authViewModel.user?.id
    }
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(message.content)
                    .padding()
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                    .cornerRadius(16)
                
                // Attachment if present
                if let attachmentURL = message.attachmentURL {
                    WebImage(url: URL(string: attachmentURL))
                        .resizable()
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5))
                        .scaledToFit()
                        .frame(maxWidth: 200)
                        .cornerRadius(8)
                }
                
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ImageAttachmentView: View {
    let url: String
    @State private var showingFullScreen = false
    
    var body: some View {
        WebImage(url: URL(string: url))
            .resizable()
            .indicator(.activity)
            .transition(.fade(duration: 0.5))
            .scaledToFit()
            .frame(maxWidth: 200)
            .cornerRadius(8)
            .onTapGesture {
                showingFullScreen = true
            }
            .fullScreenCover(isPresented: $showingFullScreen) {
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    WebImage(url: URL(string: url))
                        .resizable()
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5))
                        .scaledToFit()
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { showingFullScreen = false }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                        Spacer()
                    }
                }
            }
    }
}
