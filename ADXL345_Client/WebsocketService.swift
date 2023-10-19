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

struct RecordOptions: OptionSet, Equatable, Hashable, Identifiable {
    let rawValue: Int
    
    var id: Int {
        rawValue
    }
    
    static let combined = RecordOptions(rawValue: 1 << 0)
    static let splitted  = RecordOptions(rawValue: 1 << 1)
    
    static let all: RecordOptions = [.combined, .splitted]
}

@MainActor
class WebsocketService: ObservableObject {
    let server = "ws://192.168.88.26:81"
    let eventLoopGroup = MultiThreadedEventLoopGroup.singleton
    
    @Published var dataPoints: Deque<AccelerationDataPoint> = []
    @Published var combinedDataPoints: Deque<CombinedAcceleration> = []
    @Published var recordingSize: Int = 128
    @Published var recordOptions: RecordOptions = .combined
    @Published var isConnected = false
    var ws: WebSocket? = nil
    
    func connect() async throws  {
        self.dataPoints = []
        self.combinedDataPoints = []


        try await WebSocket.connect(to: server, on: eventLoopGroup) {  [weak self] ws in
            DispatchQueue.main.async {
                self?.isConnected = true
            }
            
            ws.onText { ws, json in
                let acceleration = try! JSONDecoder().decode(Acceleration.self, from: json.data(using: .utf8)!)
                
                DispatchQueue.main.async {
                    guard let self else {return}
                    
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
            }
            
            self?.ws = ws
        }.get()
    }

    func onDisconnect() async throws {
        try await ws?.close()
        isConnected = false
    }
}
