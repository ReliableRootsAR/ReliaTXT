import Foundation
import Firebase
import FirebaseMessaging
import UserNotifications
import FirebaseAuth

class NotificationService: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = NotificationService()
    private let firebaseService = FirebaseService.shared
    
    private override init() {
        super.init()
    }
    
    func initialize() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        requestAuthorization()
        registerForRemoteNotifications()
    }
    
    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification authorization granted")
            } else if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }
    
    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let ticketId = userInfo["ticketId"] as? String {
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenTicket"),
                object: nil,
                userInfo: ["ticketId": ticketId]
            )
        }
        
        completionHandler()
    }
    
    // MARK: - MessagingDelegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        UserDefaults.standard.set(token, forKey: "FCMToken")
        
        if let currentUserId = Auth.auth().currentUser?.uid {
            Task {
                do {
                    if let user = try await firebaseService.getUser(
                        id: currentUserId
                    ) {
                        // Use the updateUser method from FirebaseService
                        try await firebaseService.updateUser(user)
                    }
                } catch {
                    print("Error updating user device token: \(error.localizedDescription)")
                }
            }
        }
    }
}
