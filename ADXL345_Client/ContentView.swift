//
//  ContentView.swift
//  ADXL345_Client
//
//  Created by Robert Koval on 15.10.2023.
//

import SwiftUI
import Charts

struct ContentView: View {
    @AppStorage(UserDefaultsKeys.wsAddress.rawValue) var wsAddress = UserDefaultsKeys.wsAddress.defaultValue
    @ObservedObject var wsService = WebsocketService()

    var body: some View {
        VStack {
            ConnectView(url: $wsAddress, connectionState: $wsService.connectionState) {
                Task {
                    do {
                        try await wsService.onConnect()
                    } catch {
                        print(error)
                    }
                }
            } onDisconnect: {
                Task {
                    do {
                        try await wsService.onDisconnect()
                    } catch {
                        print(error)
                    }
                }
            }

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

            Picker("Sample Size", selection: $wsService.recordingSize) {
                Text("128").tag(128)
                Text("256").tag(256)
                Text("512").tag(512)
                Text("1024").tag(1024)

            }
            .pickerStyle(SegmentedPickerStyle())

            if wsService.recordOptions.contains(.combined) {
                Chart(wsService.combinedDataPoints) { point in
                    LineMark(x: .value("Time", point.date),
                             y: .value("Value", point.value)
                    )
                    .interpolationMethod(.catmullRom)
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
        }
        .padding()
    }
}

struct ConnectView: View {
    @Binding var url: String
    @Binding var connectionState: ConnectionState
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    @FocusState var focusField: Bool

    var body: some View {
        HStack {
                TextField("URL:Port", text: $url)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusField, equals: true)
                    .disabled(connectionState == .connected)
                    .disabled(connectionState == .connecting)
#if os(iOS)
                    .keyboardType(.numbersAndPunctuation)
#endif

            if connectionState == .connected {
                Button("Disconnect") {
                    onDisconnect()
                }
                .disabled(connectionState == .disconnecting)
            } else {
                Button("Connect") {
                    onConnect()
                }
                .disabled(url.isEmpty)
                .disabled(connectionState == .connecting)
            }
        }
        .onAppear(perform: {
#if os(macOS)  // TODO: How to disable focused by default?
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusField = false
            }
#endif
        })
    }
}

#Preview {
    ContentView()
}

extension Axis: Plottable { }

