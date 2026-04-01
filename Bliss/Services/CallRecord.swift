//
//  CallRecord.swift
//  Bliss
//
//  Created by Cong Huy Kieu on 2026-03-22.
//


import CallKit
import FirebaseFirestore
import AVFoundation
import Combine

struct CallRecord: Codable {
    let callId: String
    let callerId: String
    let callerName: String
    let receiverId: String
    var status: String  // "ringing" | "accepted" | "declined" | "ended"
    let startedAt: Date
}

@MainActor
final class CallService: NSObject, ObservableObject {
    static let shared = CallService()

    @Published var activeCall: CallRecord?
    @Published var incomingCall: CallRecord?
    @Published var callState: CallState = .idle

    enum CallState {
        case idle, ringing, active, ended
    }

    private let db = Firestore.firestore()
    private let provider: CXProvider
    private let callController = CXCallController()
    private var callListener: ListenerRegistration?
    private(set) var activeCallId: UUID?

    private override init() {
        let config = CXProviderConfiguration()
        config.supportsVideo = false
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.generic]
        provider = CXProvider(configuration: config)
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    // MARK: - Outgoing Call

    func startCall(to user: FirestoreUser, from currentUser: FirestoreUser) async throws {
        let callId = UUID().uuidString
        let uuid = UUID()
        activeCallId = uuid

        let record = CallRecord(
            callId: callId,
            callerId: currentUser.userId,
            callerName: currentUser.username,
            receiverId: user.userId,
            status: "ringing",
            startedAt: Date()
        )
        activeCall = record
        callState = .ringing

        try db.collection("calls").document(callId).setData(from: record)

        listenForCallUpdates(callId: callId, uuid: uuid)

        let handle = CXHandle(type: .generic, value: user.username)
        let startAction = CXStartCallAction(call: uuid, handle: handle)
        startAction.contactIdentifier = user.username
        let transaction = CXTransaction(action: startAction)

        try await callController.request(transaction)
        provider.reportOutgoingCall(with: uuid, startedConnectingAt: nil)
    }

    // MARK: - Accept Incoming Call

    func acceptIncomingCall(_ record: CallRecord, uuid: UUID) async throws {
        activeCall = record
        activeCallId = uuid
        callState = .active

        try await db.collection("calls").document(record.callId)
            .updateData(["status": "accepted"])

        provider.reportOutgoingCall(with: uuid, connectedAt: Date())
        listenForCallUpdates(callId: record.callId, uuid: uuid)
    }

    // MARK: - Decline / End

    func declineCall(_ record: CallRecord) {
        Task {
            try? await db.collection("calls").document(record.callId)
                .updateData(["status": "declined"])
            endCallLocally()
        }
    }

    func endCall() {
        guard let call = activeCall, let uuid = activeCallId else { return }
        Task {
            try? await db.collection("calls").document(call.callId)
                .updateData(["status": "ended"])
        }
        let end = CXEndCallAction(call: uuid)
        callController.request(CXTransaction(action: end)) { _ in }
        endCallLocally()
    }

    private func endCallLocally() {
        callListener?.remove()
        activeCall = nil
        incomingCall = nil
        activeCallId = nil
        callState = .idle
    }

    // MARK: - Listen for incoming calls

    func listenForIncomingCalls(userId: String) {
        db.collection("calls")
            .whereField("receiverId", isEqualTo: userId)
            .whereField("status", isEqualTo: "ringing")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                guard let doc = snapshot?.documents.first,
                      let record = try? doc.data(as: CallRecord.self) else { return }

                Task { @MainActor in
                    guard self.callState == .idle else { return }
                    self.incomingCall = record
                    self.callState = .ringing

                    let uuid = UUID()
                    self.activeCallId = uuid

                    let update = CXCallUpdate()
                    update.remoteHandle = CXHandle(type: .generic, value: record.callerName)
                    update.hasVideo = false
                    update.localizedCallerName = record.callerName

                    self.provider.reportNewIncomingCall(with: uuid, update: update) { error in
                        if let error {
                            print("CallKit report error: \(error)")
                        }
                    }
                }
            }
    }

    private func listenForCallUpdates(callId: String, uuid: UUID) {
        callListener?.remove()
        callListener = db.collection("calls").document(callId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self,
                      let data = snapshot?.data(),
                      let status = data["status"] as? String else { return }

                Task { @MainActor in
                    switch status {
                    case "accepted":
                        self.callState = .active
                        self.provider.reportOutgoingCall(with: uuid, connectedAt: Date())
                    case "declined", "ended":
                        self.endCallLocally()
                        let end = CXEndCallAction(call: uuid)
                        self.callController.request(CXTransaction(action: end)) { _ in }
                    default:
                        break
                    }
                }
            }
    }
}

// MARK: - CXProviderDelegate

extension CallService: CXProviderDelegate {
    nonisolated func providerDidReset(_ provider: CXProvider) {
        Task { @MainActor in self.endCallLocally() }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        Task { @MainActor in
            guard let record = self.incomingCall else {
                action.fail(); return
            }
            try? await self.acceptIncomingCall(record, uuid: action.callUUID)
            action.fulfill()
        }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        Task { @MainActor in
            if let call = self.activeCall ?? self.incomingCall {
                try? await self.db.collection("calls").document(call.callId)
                    .updateData(["status": "ended"])
            }
            self.endCallLocally()
            action.fulfill()
        }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        action.fulfill()
    }
}
