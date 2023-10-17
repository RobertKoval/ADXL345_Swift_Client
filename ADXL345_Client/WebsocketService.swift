//
//  WebsocketService.swift
//  ADXL345_Client
//
//  Created by Robert Koval on 15.10.2023.
//

import Foundation
import WebSocketKit
import NIOPosix
import Accelerate


class WebsocketService: ObservableObject {
    let server = "ws://192.168.88.26:81"
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    @Published var dataPoints: [AccelerationDataPoint] = []
    @Published var combinedDataPoints: [CombinedAcceleration] = []
    @Published var fourier: [FourierTransformPoints] = []

    var ws: WebSocket? = nil

    func connect() async throws  {
        DispatchQueue.main.async {
            self.dataPoints = []
            self.combinedDataPoints = []
        }
        try await WebSocket.connect(to: server, on: eventLoopGroup) {  [weak self] ws in
            ws.onText { ws, json in
                let acceleration = try! JSONDecoder().decode(Acceleration.self, from: json.data(using: .utf8)!)

                DispatchQueue.main.async {
                    guard let self else {return}
                    self.dataPoints.append(contentsOf: unpack(acceleration))
                    self.combinedDataPoints.append(combine(acceleration))

                    if (isPowerOfTwo(self.combinedDataPoints.count)) {
                        self.fourier = performFourierTransform(combinedDataPoints: self.combinedDataPoints)
                    }
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

func isPowerOfTwo(_ n: Int) -> Bool {
    return n > 0 && (n & (n - 1)) == 0
}

func calculateSampleRate(_ data: [CombinedAcceleration]) -> Double  {
    guard  data.count > 1 else { return 0 }

    let firstDate = data.first!.date
    let lastDate = data.last!.date
    let totalTime = lastDate.timeIntervalSince(firstDate)
    let averageInterval = totalTime / Double(data.count - 1)
    return 1.0 / averageInterval
}

struct FourierTransformPoints: Identifiable {
    let id = UUID()
    let value: Double
    let frequency: Double
}

func performFourierTransform(combinedDataPoints: [CombinedAcceleration]) -> [FourierTransformPoints] {
    let values = combinedDataPoints.map(\.value)
    let N = values.count
    let samplingRate = calculateSampleRate(combinedDataPoints)
    let frequencyResolution = samplingRate / Double(N)

    var real = [Double](repeating: 0.0, count: N)
    var imaginary = [Double](repeating: 0.0, count: N)
    var tempSplitComplex = DSPDoubleSplitComplex(realp: &real, imagp: &imaginary)

    guard let setup = vDSP_DFT_zop_CreateSetupD(
        nil,
        vDSP_Length(N),
        vDSP_DFT_Direction.FORWARD) else {
        fatalError("can't create vDSP_DFT_Setup")
    }
    vDSP_DFT_ExecuteD(setup, values, [Double](repeating: 0.0, count: N), &real, &imaginary)
    vDSP_DFT_DestroySetupD(setup)

    var magnitudes = [Double](repeating: 0, count: N)
    vDSP_zvmagsD(&tempSplitComplex, 1, &magnitudes, 1, vDSP_Length(N))

    // Pairing the magnitudes with their corresponding frequencies
    var result: [FourierTransformPoints] = []
    for i in 0..<(N/2) { // We take only the first half for real signals
        let frequency = frequencyResolution * Double(i)
        let point = FourierTransformPoints(value: magnitudes[i], frequency: frequency)
        result.append(point)
    }

    return result
}
