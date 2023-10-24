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
            ConnectView(url: $wsAddress) {
                Task {
                    try await wsService.onConnect()
                }
            }
            .disabled(wsService.isConnected)

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

struct ConnectView: View {
    enum IPAddressField: Hashable {
        case focused
    }

    @FocusState var focusField: IPAddressField?
    @Binding var url: String
    let onConnect: () -> Void

    var body: some View {
        HStack {
            Section {
                TextField("URL:Port", text: $url)
                    .focused($focusField, equals: .focused)
#if os(iOS)
                    .keyboardType(.numbersAndPunctuation)
#endif
            }

            Button("Connect") {
                onConnect()
            }
            .disabled(url.isEmpty)
        }

        .onAppear(perform: {

#if os(macOS)  // TODO: How to disable focused by default?
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusField = nil
            }
#endif
        })
    }
}

#Preview {
    ContentView()
}

extension Axis: Plottable { }

