//
//  AboutView.swift
//  HEPToolkit
//
//  Created by Ethan Qiu on 2/3/2026.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "atom")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("HEP Toolkit")
                .font(.largeTitle.bold())

            VStack(spacing: 8) {
                Text("A small collection of tools for high-energy physicists")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("Version 0.2.0 • Built for macOS")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("PRL word counter • Unit converter • Plot data extractor • More (coming)")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Text("Made with Grok, Codex, and Ethan Qiu")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text("chiu.yyucheng@gmail.com")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .navigationTitle("About")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AboutView()
}
