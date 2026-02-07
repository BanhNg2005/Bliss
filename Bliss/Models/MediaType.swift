import Foundation
import Combine

enum MediaType: Int16, CaseIterable, Identifiable {
    case image = 0
    case video = 1
    case reel = 2

    var id: Int16 { rawValue }

    var title: String {
        switch self {
        case .image:
            return "Image"
        case .video:
            return "Video"
        case .reel:
            return "Reel"
        }
    }

    var systemImage: String {
        switch self {
        case .image:
            return "photo"
        case .video:
            return "video"
        case .reel:
            return "play.rectangle"
        }
    }
}
