import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private var handle: AuthStateDidChangeListenerHandle?
    let firebaseService: FirebaseService
    
    init(firebaseService: FirebaseService = .shared) {
        self.firebaseService = firebaseService
        checkAuthState()
    }
    
    private func checkAuthState() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, authResult in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isAuthenticated = authResult != nil
                
                if let userId = authResult?.uid {
                    do {
                        let user = try await self.firebaseService.getUser(id: userId)
                        self.user = user
                    } catch {
                        // User is authenticated but profile doesn't exist
                        self.user = nil
                        print("User profile not found: \(error)")
                    }
                } else {
                    self.isAuthenticated = false
                    self.user = nil
                }
            }
        }
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws {
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Create Authentication account
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // 2. Create user profile in Firestore
            let newUser = User(
                id: result.user.uid,
                email: email,
                firstName: firstName,
                lastName: lastName,
                role: .locator,
                isActive: true,
                createdAt: Date()
            )
            
            try await firebaseService.createUser(newUser)
            self.user = newUser
            self.isAuthenticated = true
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = try await firebaseService.getUser(id: result.user.uid)
            self.user = user
            self.isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

enum AuthError: LocalizedError {
    case weakPassword
    
    var errorDescription: String? {
        switch self {
        case .weakPassword:
            return "Password must be at least 6 characters long"
        }
    }
}
