//
//  ContentView.swift
//  ADXL345_Client
//
//  Created by Robert Koval on 15.10.2023.
//

import SwiftUI

struct ContentView: View {
    let wsService = WebsocketService()

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
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
