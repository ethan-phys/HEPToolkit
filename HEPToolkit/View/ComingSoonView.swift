//
//  ComingSoon.swift
//  HEPToolkit
//
//  Created by 邱渔骋 on 2/3/2026.
//

import SwiftUI

struct ComingSoonView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 80))
                .foregroundStyle(.gray)

            Text("Coming Soon")
                .font(.largeTitle.bold())

            Text("This tool is under development.\nCheck back later!")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("New Tool (Coming soon)")
    }
}

#Preview {
    ComingSoonView()
}
