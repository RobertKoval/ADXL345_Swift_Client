//
//  WebsocketService.swift
//  ADXL345_Client
//
//  Created by Robert Koval on 15.10.2023.
//

import Foundation
import WebSocketKit
import NIOPosix

class WebsocketService: ObservableObject {
    let server = "ws://192.168.88.26:81"
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    @MainActor @Published var dataPoints: [AccelerationDataPoint] = []

    var ws: WebSocket? = nil

    func connect() async throws  {
        try await WebSocket.connect(to: server, on: eventLoopGroup) {  [weak self] ws in
            ws.onText { ws, json in
                let acceleration = try! JSONDecoder().decode(Acceleration.self, from: json.data(using: .utf8)!)

                let dataPoints = unpack(acceleration)



                DispatchQueue.main.async {
                    self?.dataPoints.append(contentsOf: dataPoints)
                }

                print(json)
            }

            self?.ws = ws
        }.get()
    }

    func onDisconnect() async throws {
        try await ws?.close()
    }
}
