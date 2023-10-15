//
//  WebsocketService.swift
//  ADXL345_Client
//
//  Created by Robert Koval on 15.10.2023.
//

import Foundation
import WebSocketKit
import NIOPosix

class WebsocketService {
    let server = "ws://192.168.88.26:81"
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2) // FIXME:

    func connect() async throws  {
        try await WebSocket.connect(to: server, on: eventLoopGroup) { ws in
            print(ws)
            ws.onBinary { ws, data in
                let acceleration = try! JSONDecoder().decode(Acceleration.self, from: data)
                print(acceleration)
            }
        }.get()

    }
}
