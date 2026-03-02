//
//  PlotExtractorView.swift
//  HEPToolkit
//
//  Created by Grok on 27/2/2026.
//  Constructed by Ethan Qiu on 27/02/2026

import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct PlotPoint: Identifiable {
    let id = UUID()
    var screenPos: CGPoint      // in image coordinate
    var realX: Double = 0
    var realY: Double = 0
}

struct PlotExtractorView: View {
    @State private var image: NSImage? = nil
    @State private var imageSize: CGSize = .zero
    @State private var points: [PlotPoint] = []
    @State private var calibX1: CGPoint?   // bottom-left-ish
    @State private var calibX2: CGPoint?   // bottom-right-ish
    @State private var calibY1: CGPoint?   // bottom-left
    @State private var calibY2: CGPoint?   // top-left-ish
    @State private var realX1: String = "0"
    @State private var realX2: String = "10"
    @State private var realY1: String = "0"
    @State private var realY2: String = "100"
    @State private var showingImporter = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Plot Data Extractor")
                .font(.title2.bold())

            HStack {
                Button("Load image") { showingImporter = true }
                if !points.isEmpty {
                    Button("Clear points") { points = [] }
                }
            }

            // Calibration inputs
            HStack(spacing: 24) {
                GroupBox("X-axis") {
                    HStack {
                        TextField("x₁", text: $realX1).frame(width: 80)
                        TextField("x₂", text: $realX2).frame(width: 80)
                    }
                }
                GroupBox("Y-axis") {
                    HStack {
                        TextField("y₁", text: $realY1).frame(width: 80)
                        TextField("y₂", text: $realY2).frame(width: 80)
                    }
                }
            }

            // Image + points overlay
            if let img = image {
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFit()
                            .onAppear { imageSize = img.size }

                        // Calibration lines (optional visual feedback)
                        if let p1 = calibX1, let p2 = calibX2 {
                            Path { path in
                                path.move(to: p1)
                                path.addLine(to: p2)
                            }
                            .stroke(Color.red, lineWidth: 2)
                        }
                        if let p1 = calibY1, let p2 = calibY2 {
                            Path { path in
                                path.move(to: p1)
                                path.addLine(to: p2)
                            }
                            .stroke(Color.blue, lineWidth: 2)
                        }

                        // Clicked points
                        ForEach(points) { point in
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                                .position(point.screenPos)
                        }
                    }
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                let loc = value.location
                                points.append(PlotPoint(screenPos: loc))
                            }
                    )
                }
                .frame(maxHeight: 500)
                .border(Color.gray.opacity(0.5))
            } else {
                Text("No image loaded")
                    .foregroundStyle(.secondary)
                    .frame(maxHeight: 500)
            }

            // Result table + export
            if !points.isEmpty {
                List(points) { p in
                    let (calX, calY) = calibratedValue(for: p.screenPos)
                    HStack {
                        Text(String(format: "%.4g", calX))
                        Text(String(format: "%.4g", calY))
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.image, .pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let img = NSImage(contentsOf: url) {
                        image = img
                    } else if url.pathExtension.lowercased() == "pdf" {
                        // very basic PDF → first page as image
                        if let pdf = PDFDocument(url: url),
                           let page = pdf.page(at: 0) {
                            let thumbnail = page.thumbnail(of: CGSize(width: 800, height: 800), for: .cropBox)
                            // Safely extract CGImage from the NSImage via bitmap representation
                            if let bitmapRep = thumbnail.representations.first as? NSBitmapImageRep,
                               let cgImage = bitmapRep.cgImage {
                                image = NSImage(cgImage: cgImage, size: .zero)
                            }
                        }
                    }
                }
            case .failure: break
            }
        }
    }

    private func calibratedValue(for pos: CGPoint) -> (Double, Double) {
        // very simple linear calibration – improve later
        guard let x1 = calibX1, let x2 = calibX2,
              let y1 = calibY1, let y2 = calibY2,
              let rx1 = Double(realX1), let rx2 = Double(realX2),
              let ry1 = Double(realY1), let ry2 = Double(realY2) else {
            return (0, 0)
        }

        let xScale = (rx2 - rx1) / Double(x2.x - x1.x)
        let xOffset = rx1 - xScale * Double(x1.x)
        let calX = xScale * Double(pos.x) + xOffset

        let yScale = (ry2 - ry1) / Double(y2.y - y1.y)
        let yOffset = ry1 - yScale * Double(y1.y)
        let calY = yScale * Double(pos.y) + yOffset

        return (calX, calY)
    }
}
