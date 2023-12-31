//
//  WebsocketService.swift
//  ADXL345_Client
//
//  Created by Robert Koval on 15.10.2023.
//

import Foundation
import WebSocketKit
import NIOPosix
import Collections

enum UserDefaultsKeys: String {
    case wsAddress

    var defaultValue: String {
        switch self {
        case .wsAddress:
            return "192.168.88.26:81"
        }
    }
}

struct RecordOptions: OptionSet, Equatable, Hashable, Identifiable {
    let rawValue: Int

    var id: Int {
        rawValue
    }

    static let combined = RecordOptions(rawValue: 1 << 0)
    static let splitted  = RecordOptions(rawValue: 1 << 1)

    static let all: RecordOptions = [.combined, .splitted]
}

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case disconnecting
}

@MainActor
class WebsocketService: ObservableObject {
    @Published var dataPoints: Deque<AccelerationDataPoint> = []
    @Published var combinedDataPoints: Deque<CombinedAcceleration> = []
    @Published var recordingSize: Int = 128
    @Published var recordOptions: RecordOptions = .combined
    @Published var connectionState: ConnectionState = .disconnected

    var ws: WebSocket? = nil

    var server: String {
        "ws://\(UserDefaults.standard.string(forKey: UserDefaultsKeys.wsAddress.rawValue) ?? UserDefaultsKeys.wsAddress.defaultValue)"
    }

    @Sendable
    func onEvent(_ ws: WebSocket, _ json: String) async -> Void {
        let acceleration = try! JSONDecoder().decode(Acceleration.self, from: json.data(using: .utf8)!)

        if self.recordOptions.contains(.combined) {
            self.combinedDataPoints.append(combine(acceleration))
            if self.combinedDataPoints.count > self.recordingSize {
                self.combinedDataPoints.removeFirst()
            }
        }

        if self.recordOptions.contains(.splitted) {
            self.dataPoints.append(contentsOf: unpack(acceleration))
            if self.dataPoints.count > self.recordingSize {
                self.dataPoints.removeFirst(3)
            }
        }
    }

    func onConnect() async throws  {
        self.dataPoints = []
        self.combinedDataPoints = []
        self.connectionState = .connecting

        ws = try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await  WebSocket.connect(to: server, on: MultiThreadedEventLoopGroup.singleton) { ws in
                        continuation.resume(returning: ws)
                    }.get()


                } catch {
                    continuation.resume(throwing: error)
                    connectionState = .disconnected
                }
            }
        }
        ws?.onText(onEvent)
        self.connectionState = .connected
    }

    func onDisconnect() async throws {
        defer { self.connectionState = .disconnected }
        self.connectionState = .disconnecting
        try await ws?.close()
    }
}
