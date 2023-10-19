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
            Picker("Record Options", selection: $wsService.recordOptions) {
                ForEach([RecordOptions.combined, .splitted, .all], id: \.self) { option in
                    if option.contains(.all) {
                        Text("All").tag(option)
                    } else if option.contains(.combined) {
                        Text("Combined").tag(option)
                    } else {
                        Text("Splitted").tag(option)
                    }
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .disabled(wsService.isConnected)
            
            Picker("Sample Size", selection: $wsService.recordingSize) {
                Text("128").tag(128)
                Text("256").tag(256)
                Text("512").tag(512)
                Text("1024").tag(1024)
                
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .disabled(wsService.isConnected)
            
            
            if wsService.recordOptions.contains(.combined) {
                Chart(wsService.combinedDataPoints) { point in
                    LineMark(x: .value("Time", point.date),
                             y: .value("Value", point.value)
                    )
                    .interpolationMethod(.cardinal)
                }
                .padding()
            }
            
            if wsService.recordOptions.contains(.splitted) {
                Chart(wsService.dataPoints) { point in
                    LineMark(x: .value("Time", point.date),
                             y: .value("Value", point.value)
                    )
                    .foregroundStyle(by: .value("Axis", point.axis))
                    .interpolationMethod(.cardinal)
                }
                .padding()
            }
            
            Button("Connect") {
                Task {
                    try await wsService.connect()
                }
            }
            .disabled(wsService.isConnected)

            Button("Disconnect") {
                Task {
                    try await wsService.onDisconnect()
                }
            }
            .disabled(!wsService.isConnected)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

extension Axis: Plottable { }

