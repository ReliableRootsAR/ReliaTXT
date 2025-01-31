import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingLogoutAlert = false
    
    var body: some View {
        // Safely unwrap optional user
        Group {
            // Use optional binding with nil coalescing to handle potential nil
            if let user = authViewModel.user ?? nil {
                VStack(spacing: 20) {
                    Text("Profile")
                        .font(.largeTitle)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(title: "Name", value: user.fullName)
                        InfoRow(title: "Email", value: user.email)
                        
                        // Optional phone number handling
                        if let phone = user.phone, !phone.isEmpty {
                            InfoRow(title: "Phone", value: phone)
                        }
                        
                        InfoRow(title: "Role", value: user.role.rawValue.capitalized)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    Button(action: { showingLogoutAlert = true }) {
                        Text("Sign Out")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .alert("Sign Out", isPresented: $showingLogoutAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Sign Out", role: .destructive) {
                        authViewModel.signOut()
                    }
                } message: {
                    Text("Are you sure you want to sign out?")
                }
            } else {
                VStack {
                    ProgressView("Loading profile...")
                    Button("Retry") {
                        // Safely handle optional current user
                        if let userId = Auth.auth().currentUser?.uid {
                            Task {
                                do {
                                    // Safely handle optional user retrieval
                                    if let user = try await authViewModel.firebaseService.getUser(id: userId) {
                                        authViewModel.user = user
                                    }
                                } catch {
                                    print("Error loading profile: \(error)")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
        }
    }
}
