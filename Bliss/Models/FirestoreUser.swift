import Foundation

struct FirestoreUser: Codable {
    let userId: String
    let username : String
    let avatarURL: String
    let createdAt: Date 
}