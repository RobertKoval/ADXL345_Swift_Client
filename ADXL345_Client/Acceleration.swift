//
//  Acceleration.swift
//  ADXL345_Client
//
//  Created by Robert Koval on 15.10.2023.
//

import Foundation

enum Axis: String {
    case axisX
    case axisY
    case axisZ
}

struct AccelerationDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let axis: Axis
    let value: Double
}

struct Acceleration: Decodable {
    let timestamp: UInt64
    let axisX: Double
    let axisY: Double
    let axisZ: Double
}

struct CombinedAcceleration: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

func unpack(_ acceleration: Acceleration) -> [AccelerationDataPoint] {
    let date = Date()

    return [
        .init(date: date, axis: .axisX, value: acceleration.axisX),
        .init(date: date, axis: .axisY, value: acceleration.axisY),
        .init(date: date, axis: .axisZ, value: acceleration.axisZ)
    ]
}

func combine(_ acceleration: Acceleration) -> CombinedAcceleration {
    CombinedAcceleration(date: .now, value: acceleration.axisX + acceleration.axisY + acceleration.axisZ)
}
