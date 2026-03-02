//
//  ContentView.swift
//  HEPToolkit
//
//  Created by Grok on 27/2/2026.
//  Constructed by Ethan Qiu on 27/02/2026

import SwiftUI

struct ContentView: View {
    @State private var selectedTool: Tool? = .prlCounter

    var body: some View {
        NavigationSplitView {
            List(Tool.allCases, selection: $selectedTool) { tool in
                Text(tool.rawValue)
                    .tag(tool)
            }
            .navigationTitle("HEP Tools")
        } detail: {
            if let tool = selectedTool {
                tool.view
                    .navigationTitle(tool.rawValue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Select a tool from the sidebar")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 700, idealWidth: 900, minHeight: 500)
    }
}

#Preview {
    ContentView()
}
