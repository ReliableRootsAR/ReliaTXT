import SwiftUI
import FirebaseAuth

struct CompleteProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Complete Your Profile")
                .font(.largeTitle)
                .bold()
            
            VStack(spacing: 15) {
                TextField("First Name", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                TextField("Last Name", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
            }
            .padding(.horizontal)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: completeProfile) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Complete Profile")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(firstName.isEmpty || lastName.isEmpty ? Color.gray : Color.blue)
            .cornerRadius(10)
            .padding(.horizontal)
            .disabled(firstName.isEmpty || lastName.isEmpty || isLoading)
        }
        .padding()
        .onAppear {
            // Check if we actually need to complete profile
            if let currentUser = Auth.auth().currentUser {
                Task {
                    do {
                        let user = try await authViewModel.firebaseService.getUser(id: currentUser.uid)
                        if user != nil {
                            // User exists, we shouldn't be on this screen
                            authViewModel.user = user
                        }
                    } catch {
                        // User doesn't exist in Firestore, which is expected
                        print("User profile doesn't exist yet")
                    }
                }
            } else {
                // No authentication, go back to login
                authViewModel.signOut()
            }
        }
    }
    
    private func completeProfile() {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "No authenticated user found"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let user = User(
                    id: currentUser.uid,
                    email: currentUser.email ?? "",
                    firstName: firstName,
                    lastName: lastName,
                    role: .locator,
                    isActive: true,
                    createdAt: Date()
                )
                try await authViewModel.firebaseService.createUser(user)
                authViewModel.user = user
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
