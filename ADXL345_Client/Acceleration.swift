//
//  Acceleration.swift
//  ADXL345_Client
//
//  Created by Robert Koval on 15.10.2023.
//

struct Acceleration: Decodable {
    let axisX: Double
    let axisY: Double
    let axisZ: Double
}
