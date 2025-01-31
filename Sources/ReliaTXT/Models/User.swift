import Foundation

struct User: Identifiable {
    let id: String
    var email: String
    var firstName: String
    var lastName: String
    var role: UserRole
    var phone: String?
    var isActive: Bool
    var deviceToken: String?
    var createdAt: Date
    
    var fullName: String {
        "\(lastName), \(firstName)"
    }
    
    enum UserRole: String, Codable {
        case locator
        case admin
        case customer
    }
}
