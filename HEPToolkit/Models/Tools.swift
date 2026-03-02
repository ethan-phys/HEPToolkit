//
//  Tool.swift
//  HEPToolkit
//
//  Created by Grok on 27/2/2026.
//  Constructed by Ethan Qiu on 27/02/2026

import SwiftUI

enum Tool: String, Identifiable, CaseIterable {
    case about = "About"
    case prlCounter    = "PRL Word Counter"
    case unitConverter = "Unit Converter"
    //case plotExtractor = "Plot Data Extractor"
    //case scalePlot = "Scale Plot"
    //case ideaArena = "Idea Arena"

    var id: String { rawValue }

    @ViewBuilder
    var view: some View {
        switch self {
        case .about: AboutView()
        case .prlCounter:    PRLWordCounterView()
        case .unitConverter: UnitConverterView_2()
        //case .plotExtractor: ComingSoonView()
        //case .scalePlot: ComingSoonView()
        //case .ideaArena: ComingSoonView()
        }
    }
}


