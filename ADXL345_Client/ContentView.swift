//
//  ContentView.swift
//  ADXL345_Client
//
//  Created by Robert Koval on 15.10.2023.
//

import SwiftUI
import Charts

struct ContentView: View {
    @ObservedObject var wsService = WebsocketService()

    var body: some View {
        VStack {
            Chart(wsService.dataPoints.suffix(1000)) { point in
                LineMark(x: .value("Time", point.date),
                         y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Axis", point.axis))
                .interpolationMethod(.cardinal)
            }

            Text("Hello, world!")
            Button("Connect") {
                Task {
                    try await wsService.connect()
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

extension Axis: Plottable { }

