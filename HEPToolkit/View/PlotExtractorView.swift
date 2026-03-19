//
//  PlotExtractorView.swift
//  HEPToolkit
//
//  Created by Grok on 27/2/2026.
//  Constructed by Ethan Qiu on 27/02/2026

import SwiftUI
import UniformTypeIdentifiers
import AppKit
import PDFKit

struct PlotDigitizerView: View {
    @State private var image: NSImage?
    @State private var calibrationPoints: [CGPoint] = []
    @State private var dataPoints: [CGPoint] = []
    @State private var selectedDataPointIDs: Set<Int> = []
    @State private var xMinText: String = "0"
    @State private var xMaxText: String = "10"
    @State private var yMinText: String = "0"
    @State private var yMaxText: String = "10"
    @State private var isCalibrating = true
    @State private var xAxisLogScale = false
    @State private var yAxisLogScale = false
    @State private var zoomScale: CGFloat = 1
    @State private var showingImporter = false
    @State private var statusMessage = "Load a plot image, set x1/x2/y1/y2 values, then click the 4 calibration points."

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button("Load Image") {
                    showingImporter = true
                }
                .buttonStyle(.bordered)

                Button("Reset") {
                    calibrationPoints = []
                    dataPoints = []
                    selectedDataPointIDs = []
                    isCalibrating = true
                    zoomScale = 1
                    statusMessage = "Calibration reset. Click x1, x2, y1, then y2."
                }
                .buttonStyle(.bordered)

                Toggle("x log", isOn: $xAxisLogScale)

                Toggle("y log", isOn: $yAxisLogScale)

                Button("Export CSV") {
                    exportCSV()
                }
                .buttonStyle(.borderedProminent)
                .disabled(dataPoints.isEmpty || calibrationPoints.count < 4)

                Spacer()
            }

            HStack(spacing: 16) {
                axisField(title: "x1", text: $xMinText)
                axisField(title: "x2", text: $xMaxText)
                axisField(title: "y1", text: $yMinText)
                axisField(title: "y2", text: $yMaxText)
                Spacer()
            }

            HStack(spacing: 16) {
                VStack(spacing: 10) {
                    zoomControls
                    figurePanel
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                pointSidebar
                    .frame(width: 260)
            }

            Text(statusMessage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.secondary)
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
                guard url.startAccessingSecurityScopedResource() else {
                    statusMessage = "Access denied to the selected image."
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }

                if let loadedImage = loadPreviewImage(from: url) {
                    image = loadedImage
                    calibrationPoints = []
                    dataPoints = []
                    selectedDataPointIDs = []
                    isCalibrating = true
                    zoomScale = 1
                    statusMessage = "Image loaded. Click x1, x2, y1, then y2."
                } else {
                    statusMessage = "Unable to read the selected image or PDF."
                }
            case .failure(let error):
                statusMessage = "Import failed: \(error.localizedDescription)"
            }
        }
    }

    func extractData() -> [(Double, Double)] {
        guard calibrationPoints.count == 4,
              image != nil else { return [] }
        return dataPoints.compactMap(mappedDataPoint).sorted { $0.0 < $1.0 }
    }

    func exportCSV() {
        let data = extractData()
        guard !data.isEmpty else {
            statusMessage = "No exportable data. Check calibration points and axis values."
            return
        }

        let csv = "x,y\n" + data.map { "\($0.0),\($0.1)" }.joined(separator: "\n")
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "plot-data.csv"
        panel.allowedFileTypes = ["csv"]
        panel.allowsOtherFileTypes = false
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try csv.write(to: url, atomically: true, encoding: .utf8)
                statusMessage = "Exported CSV to \(url.lastPathComponent)."
            } catch {
                statusMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }

    private func parsedAxisValues(_ minText: String, _ maxText: String) -> (Double, Double)? {
        guard let minValue = Double(minText),
              let maxValue = Double(maxText),
              minValue != maxValue else {
            return nil
        }
        return (minValue, maxValue)
    }

    private func calibrationInstruction(for count: Int) -> String {
        switch count {
        case 0:
            return "Click x1, x2, y1, then y2."
        case 1:
            return "Captured x1. Next click x2."
        case 2:
            return "Captured x2. Next click y1."
        case 3:
            return "Captured y1. Next click y2."
        default:
            return "Calibration complete. Click points on the plotted curve."
        }
    }

    private func loadPreviewImage(from url: URL) -> NSImage? {
        if let image = NSImage(contentsOf: url) {
            return image
        }

        guard url.pathExtension.lowercased() == "pdf",
              let document = PDFDocument(url: url),
              let page = document.page(at: 0) else {
            return nil
        }

        let pageBounds = page.bounds(for: .mediaBox)
        let size = NSSize(width: max(pageBounds.width, 1), height: max(pageBounds.height, 1))
        let image = NSImage(size: size)

        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        page.draw(with: .mediaBox, to: NSGraphicsContext.current!.cgContext)
        image.unlockFocus()

        return image
    }

    private var zoomControls: some View {
        HStack(spacing: 10) {
            Text("Zoom")
                .foregroundStyle(.secondary)

            Button {
                zoomScale = max(1, zoomScale / 1.25)
            } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .disabled(image == nil || zoomScale <= 1)

            Slider(value: $zoomScale, in: 1...8, step: 0.25)
                .frame(maxWidth: 180)
                .disabled(image == nil)

            Button {
                zoomScale = min(8, zoomScale * 1.25)
            } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .disabled(image == nil || zoomScale >= 8)

            Button("Fit") {
                zoomScale = 1
            }
            .disabled(image == nil || abs(zoomScale - 1) < 0.001)

            Text(String(format: "%.2fx", zoomScale))
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Spacer()
        }
        .buttonStyle(.bordered)
    }

    private var figurePanel: some View {
        ZStack {
            if let img = image {
                GeometryReader { geometry in
                    let baseSize = fittedImageSize(in: geometry.size, imageSize: img.size)
                    let scaledSize = CGSize(width: baseSize.width * zoomScale, height: baseSize.height * zoomScale)
                    let canvasSize = CGSize(
                        width: max(geometry.size.width, scaledSize.width),
                        height: max(geometry.size.height, scaledSize.height)
                    )
                    let imageOrigin = CGPoint(
                        x: (canvasSize.width - scaledSize.width) / 2,
                        y: (canvasSize.height - scaledSize.height) / 2
                    )
                    let imageRect = CGRect(origin: imageOrigin, size: scaledSize)

                    ScrollView([.horizontal, .vertical]) {
                        ZStack(alignment: .topLeading) {
                            Color.clear
                                .frame(width: canvasSize.width, height: canvasSize.height)

                            Image(nsImage: img)
                                .resizable()
                                .frame(width: scaledSize.width, height: scaledSize.height)
                                .position(
                                    x: imageOrigin.x + scaledSize.width / 2,
                                    y: imageOrigin.y + scaledSize.height / 2
                                )

                            ForEach(0..<calibrationPoints.count, id: \.self) { i in
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 12, height: 12)
                                    .position(viewPoint(fromImagePoint: calibrationPoints[i], imageRect: imageRect, imageSize: img.size))
                            }

                            ForEach(0..<dataPoints.count, id: \.self) { i in
                                Circle()
                                    .fill(selectedDataPointIDs.contains(i) ? Color.orange : Color.red)
                                    .frame(width: 8, height: 8)
                                    .position(viewPoint(fromImagePoint: dataPoints[i], imageRect: imageRect, imageSize: img.size))
                            }
                        }
                        .frame(width: canvasSize.width, height: canvasSize.height)
                        .contentShape(Rectangle())
                        .onTapGesture(coordinateSpace: .local) { location in
                            guard let imagePoint = imagePoint(fromViewPoint: location, imageRect: imageRect, imageSize: img.size) else {
                                statusMessage = "Click inside the plot image area."
                                return
                            }

                            if isCalibrating {
                                if calibrationPoints.count < 4 {
                                    calibrationPoints.append(imagePoint)
                                    statusMessage = calibrationInstruction(for: calibrationPoints.count)
                                }
                                if calibrationPoints.count == 4 {
                                    isCalibrating = false
                                    statusMessage = "Calibration complete. Click points on the plotted curve."
                                }
                            } else {
                                dataPoints.append(imagePoint)
                                selectedDataPointIDs = [dataPoints.count - 1]
                                statusMessage = "Added \(dataPoints.count) data point\(dataPoints.count == 1 ? "" : "s")."
                            }
                        }
                    }
                }
            } else {
                Text("Load an image.")
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(8)
    }

    private var pointSidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Picked Points")
                .font(.headline)

            HStack(spacing: 8) {
                Button("Delete Selected") {
                    deleteSelectedPoints()
                }
                .disabled(selectedDataPointIDs.isEmpty)

                Button("Clear Points") {
                    dataPoints = []
                    selectedDataPointIDs = []
                    statusMessage = "Cleared all picked data points."
                }
                .disabled(dataPoints.isEmpty)
            }
            .buttonStyle(.bordered)

            if let calibrationErrorText {
                Text(calibrationErrorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(dataPoints.indices), id: \.self) { index in
                            Button {
                                toggleSelection(for: index)
                            } label: {
                                HStack(alignment: .top, spacing: 8) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Point \(index + 1)")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.primary)

                                        if let mapped = mappedDataPoint(dataPoints[index]) {
                                            Text(String(format: "x: %.6g", mapped.0))
                                                .foregroundStyle(.secondary)
                                            Text(String(format: "y: %.6g", mapped.1))
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text(String(format: "px: %.1f", dataPoints[index].x))
                                                .foregroundStyle(.secondary)
                                            Text(String(format: "py: %.1f", dataPoints[index].y))
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Button {
                                        deletePoint(at: index)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedDataPointIDs.contains(index) ? Color.orange.opacity(0.18) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedDataPointIDs.contains(index) ? Color.orange : Color.secondary.opacity(0.18), lineWidth: 1)
                                )
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .id(index)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: .infinity)
                .onChange(of: dataPoints.count) { _, newCount in
                    guard newCount > 0 else { return }
                    withAnimation {
                        proxy.scrollTo(newCount - 1, anchor: .bottom)
                    }
                }
            }

            Text(sidebarFooterText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(8)
    }

    private var sidebarFooterText: String {
        if calibrationPoints.count < 4 {
            return "Complete calibration to see converted axis coordinates."
        }
        if calibrationErrorText != nil {
            return "Fix the highlighted calibration issue to restore converted coordinates."
        }
        return "Selected points are highlighted in orange on the plot."
    }

    private var calibrationErrorText: String? {
        guard calibrationPoints.count == 4 else { return nil }
        guard let xValues = parsedAxisValues(xMinText, xMaxText),
              let yValues = parsedAxisValues(yMinText, yMaxText) else {
            return "Calibration values must be valid numbers and x1 != x2, y1 != y2."
        }
        if xAxisLogScale && (xValues.0 <= 0 || xValues.1 <= 0) {
            return "x log requires positive x1 and x2 calibration values."
        }
        if yAxisLogScale && (yValues.0 <= 0 || yValues.1 <= 0) {
            return "y log requires positive y1 and y2 calibration values."
        }
        return nil
    }

    private func mappedDataPoint(_ point: CGPoint) -> (Double, Double)? {
        guard calibrationPoints.count == 4 else { return nil }
        guard let xValues = parsedAxisValues(xMinText, xMaxText),
              let yValues = parsedAxisValues(yMinText, yMaxText) else {
            return nil
        }
        if xAxisLogScale && (xValues.0 <= 0 || xValues.1 <= 0) {
            return nil
        }
        if yAxisLogScale && (yValues.0 <= 0 || yValues.1 <= 0) {
            return nil
        }

        let x1 = calibrationPoints[0]
        let x2 = calibrationPoints[1]
        let y1 = calibrationPoints[2]
        let y2 = calibrationPoints[3]

        let dxPixel = x2.x - x1.x
        let dyPixel = y2.y - y1.y
        guard abs(dxPixel) > .ulpOfOne, abs(dyPixel) > .ulpOfOne else { return nil }

        let fracX = (point.x - x1.x) / dxPixel
        let fracY = (y1.y - point.y) / abs(dyPixel)

        let realX: Double
        if xAxisLogScale {
            realX = pow(10, log10(xValues.0) + fracX * (log10(xValues.1) - log10(xValues.0)))
        } else {
            realX = xValues.0 + fracX * (xValues.1 - xValues.0)
        }

        let realY: Double
        if yAxisLogScale {
            realY = pow(10, log10(yValues.0) + fracY * (log10(yValues.1) - log10(yValues.0)))
        } else {
            realY = yValues.0 + fracY * (yValues.1 - yValues.0)
        }

        return (realX, realY)
    }

    private func deleteSelectedPoints() {
        guard !selectedDataPointIDs.isEmpty else { return }
        dataPoints = dataPoints.enumerated().filter { !selectedDataPointIDs.contains($0.offset) }.map(\.element)
        selectedDataPointIDs = []
        statusMessage = "Deleted selected data points."
    }

    private func toggleSelection(for index: Int) {
        if selectedDataPointIDs.contains(index) {
            selectedDataPointIDs.remove(index)
        } else {
            selectedDataPointIDs.insert(index)
        }
    }

    private func deletePoint(at index: Int) {
        guard dataPoints.indices.contains(index) else { return }
        dataPoints.remove(at: index)
        selectedDataPointIDs = Set(selectedDataPointIDs.compactMap { selectedIndex in
            if selectedIndex == index {
                return nil
            }
            return selectedIndex > index ? selectedIndex - 1 : selectedIndex
        })
        statusMessage = "Deleted point \(index + 1)."
    }

    private func fittedImageSize(in containerSize: CGSize, imageSize: CGSize) -> CGSize {
        guard containerSize.width > 0,
              containerSize.height > 0,
              imageSize.width > 0,
              imageSize.height > 0 else {
            return .zero
        }

        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    private func displayedImageRect(in containerSize: CGSize, imageSize: CGSize) -> CGRect {
        let fittedSize = fittedImageSize(in: containerSize, imageSize: imageSize)
        let origin = CGPoint(
            x: (containerSize.width - fittedSize.width) / 2,
            y: (containerSize.height - fittedSize.height) / 2
        )
        return CGRect(origin: origin, size: fittedSize)
    }

    private func imagePoint(fromViewPoint point: CGPoint, imageRect: CGRect, imageSize: CGSize) -> CGPoint? {
        guard imageRect.contains(point),
              imageRect.width > 0,
              imageRect.height > 0 else {
            return nil
        }

        let normalizedX = (point.x - imageRect.minX) / imageRect.width
        let normalizedY = (point.y - imageRect.minY) / imageRect.height
        return CGPoint(x: normalizedX * imageSize.width, y: normalizedY * imageSize.height)
    }

    private func viewPoint(fromImagePoint point: CGPoint, imageRect: CGRect, imageSize: CGSize) -> CGPoint {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return .zero
        }

        let normalizedX = point.x / imageSize.width
        let normalizedY = point.y / imageSize.height
        return CGPoint(
            x: imageRect.minX + normalizedX * imageRect.width,
            y: imageRect.minY + normalizedY * imageRect.height
        )
    }

    @ViewBuilder
    private func axisField(title: String, text: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 90)
        }
    }
}
