import SwiftUI

struct ActiveCallBannerView: View {
    @ObservedObject var callService: CallService

    var body: some View {
        if let call = callService.activeCall ?? callService.incomingCall {
            callBanner(call: call)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: callService.callState)
        }
    }

    @ViewBuilder
    private func callBanner(call: CallRecord) -> some View {
        HStack(spacing: 14) {
            // Animated pulse circle
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .scaleEffect(callService.callState == .ringing ? 1.3 : 1.0)
                    .animation(
                        callService.callState == .ringing
                            ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                            : .default,
                        value: callService.callState
                    )

                Image(systemName: "phone.fill")
                    .foregroundStyle(statusColor)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(callService.callState == .ringing ? "Calling..." : "In Call")
                    .font(.subheadline.weight(.semibold))
                Text(call.callerName == call.callerId ? call.callerName : call.callerName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Accept button (only for incoming ringing)
            if callService.incomingCall != nil && callService.callState == .ringing {
                Button {
                    guard let uuid = callService.activeCallId else { return }
                    Task {
                        try? await callService.acceptIncomingCall(call, uuid: uuid)
                    }
                } label: {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 18))
                        .padding(10)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
            }

            // End / decline button
            Button {
                if callService.incomingCall != nil && callService.callState == .ringing {
                    callService.declineCall(call)
                } else {
                    callService.endCall()
                }
            } label: {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 18))
                    .padding(10)
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .padding(.horizontal, 12)
    }

    private var statusColor: Color {
        switch callService.callState {
        case .ringing: return .orange
        case .active: return .green
        default: return .gray
        }
    }
}