import SwiftUI
import CoreData

struct MessageBubbleView: View {
    let message: Message
    let isFromCurrentUser: Bool

    private let accent = Color(red: 0.78, green: 0.09, blue: 0.2)

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            } else {
                // Avatar for other user
                ZStack {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 28, height: 28)
                    Text(String((message.senderId ?? "?").prefix(1)).uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 3) {
                Text(message.text ?? "")
                    .font(.subheadline)
                    .foregroundStyle(isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isFromCurrentUser ? accent : Color(.systemGray5))
                    .clipShape(BubbleShape(isFromCurrentUser: isFromCurrentUser))

                if let timestamp = message.timestamp {
                    Text(timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
            }

            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
}

private struct BubbleShape: Shape {
    let isFromCurrentUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailRadius: CGFloat = 4

        var path = Path()

        if isFromCurrentUser {
            // Rounded on all corners except bottom-right
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                        radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - tailRadius))
            path.addArc(center: CGPoint(x: rect.maxX - tailRadius, y: rect.maxY - tailRadius),
                        radius: tailRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                        radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                        radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            // Rounded on all corners except bottom-left
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                        radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                        radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + tailRadius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + tailRadius, y: rect.maxY - tailRadius),
                        radius: tailRadius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                        radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }

        path.closeSubpath()
        return path
    }
}