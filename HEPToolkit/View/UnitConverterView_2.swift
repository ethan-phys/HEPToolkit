//
//  UnitConverterView_2.swift
//  HEPToolkit
//
//  Created by Grok on 2/3/2026.
//

import SwiftUI

// SI / astro base → natural (ℏ = c = 1)
let siBaseToNatural: [String: (factor: Double, power: Int)] = [
    // Basic SI units
    "g":          (5.609588650e32,    1),
    "m":          (5.067730e6,       -1),     // length
    "s":          (1.5192675e15,     -1),     // time
    "J":          (6.241509074e18,    1),     // energy
    "eV":         (1.0,               1),
    "pc":         (1.551319e31,      -1),     // parsec
    "AU":         (2.063e23,         -1),     // astronomical unit
    "ly":         (3.156e37,         -1),     // light year
    "yr":         (4.794e22,         -1),     // Julian year
    "M⊙":         (1.9885e66,         1),     // solar mass
    "erg":        (6.241509074e11,    1),     // Energy
    "barn":       (2.568e-15,        -2),     // cross section
    "Gauss":      (1.95e-2,           2),     // magnetic field
    "Hz":         (6.582119569e-16,   1),     // frequency → energy
    "K":          (8.617e-5,          1),     // Temperature Kelvin
]

// Prefixes
let prefixes: [(symbol: String, exp: Int)] = [
    ("Y", 24), ("Z", 21), ("E", 18), ("P", 15), ("T", 12),
    ("G",  9), ("M",  6), ("k",  3),
    ("",   0),
    ("m", -3), ("μ", -6), ("n", -9), ("p", -12),
    ("f", -15),("a", -18),
]

struct UnitFactor: Identifiable {
    let id = UUID()
    var prefixExp: Int
    var baseUnit: String
    var unitExp:  String
}

struct UnitConverterView_2: View {
    
    @Environment(ToolkitStore.self) private var store
    @State var shouldClear: Bool = false
    
    private let rowHeight: CGFloat = 22
    private let labelWidth: CGFloat = 45

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
             VStack {
                // ─── LEFT: SI/Astro → Natural ───
                VStack(alignment: .leading, spacing: 16) {
                    Text("SI/Astro → Natural")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Your existing value input
                    HStack {
                        Text("Value:")
                            .font(.headline)
                            .frame(width: labelWidth, alignment: .leading)
                        TextField("Value", text: Binding(
                            get: { store.valueStr },
                            set: { store.valueStr = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        
                        // First row (no ×)
                        HStack(alignment: .center, spacing: 12) {
                            Text("Units:")
                                .font(.headline)
                                .frame(width: labelWidth, alignment: .leading)

                            if let first = store.factors.first {
                                let firstBinding = Binding<UnitFactor>(
                                    get: { store.factors.first(where: { $0.id == first.id }) ?? first },
                                    set: { newValue in
                                        if let idx = store.factors.firstIndex(where: { $0.id == first.id }) {
                                            store.factors[idx] = newValue
                                        }
                                    }
                                )
                                unitRow(for: firstBinding)
                            } else {
                                Text("add units")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: rowHeight)

                        // Additional rows with ×
                        ForEach(store.factors.dropFirst(), id: \.id) { factor in
                            let binding = Binding<UnitFactor>(
                                get: { store.factors.first(where: { $0.id == factor.id }) ?? factor },
                                set: { newValue in
                                    if let idx = store.factors.firstIndex(where: { $0.id == factor.id }) {
                                        store.factors[idx] = newValue
                                    }
                                }
                            )
                            
                            HStack(alignment: .center, spacing: 12) {
                                Text("×")
                                    .font(.body)
                                    .frame(width: labelWidth, alignment: .center)
                                unitRow(for: binding)
                            }
                            .frame(height: rowHeight)
                        }
                    }
                    
                    
                    // Buttons
                    HStack(spacing: 24) {
                        Button {
                            store.factors.append(UnitFactor(prefixExp: 0, baseUnit: "m", unitExp: "0"))
                        } label: {
                            Label("Add unit", systemImage: "plus.circle")
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Clear") {
                            DispatchQueue.main.async {
                                store.factors = []
                                store.valueStr = "1.0"
                                store.outputPrefixExp = 0
                                store.unit_result = ""
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.red.opacity(0.8))
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    HStack(spacing: 20) {
                        // Output prefix picker (left side)
                        HStack(spacing: 12) {
                            Text("Output in:")
                                .font(.subheadline)
                            Picker("", selection: Binding(
                                get: { store.outputPrefixExp },
                                set: { store.outputPrefixExp = $0 }
                            )) {
                                ForEach(prefixes, id: \.exp) { p in
                                    Text(p.symbol.isEmpty ? "—" : p.symbol).tag(p.exp)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 70)
                        }

                        Button("Convert") {
                            convertLeft()  // rename your convert() to convertLeft()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 8)

                    if !store.unit_result.isEmpty {
                        Text(store.unit_result)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
             }
            .frame(maxHeight: 700, alignment: .center)
            .padding()
            .background()  // card style

                 // Right side – Natural → SI/Astro
            VStack {
                // ─── RIGHT: Natural → SI/Astro ───
                VStack(alignment: .leading, spacing: 16) {
                    Text("Natural → SI/Astro")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {  // reduced spacing
                        Text("Value:")
                            .font(.headline)
                            .frame(width: labelWidth, alignment: .leading)

                        TextField("", text: Binding(
                            get: { store.valueStr_rev },
                            set: { store.valueStr_rev = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)  // slightly narrower

                        Text("(")
                            .font(.body)

                        Picker("", selection: Binding(
                            get: { store.inputPrefixExp_rev },
                            set: { store.inputPrefixExp_rev = $0 }
                        )) {
                            ForEach(prefixes, id: \.exp) { p in
                                Text(p.symbol.isEmpty ? "" : p.symbol).tag(p.exp)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 45)  // narrower picker

                        Text("eV) ^")
                            .font(.body)

                        TextField("", text: Binding(
                            get: { store.inputUnitExp_rev },
                            set: { store.inputUnitExp_rev = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 40, height: rowHeight - 4)
                        .multilineTextAlignment(.center)
                    }
                    .padding(.top, 4)  // reduced vertical padding
                    
                    Divider()
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        
                        // First row (no ×)
                        HStack(alignment: .center, spacing: 12) {
                            Text("Units:")
                                .font(.headline)
                                .frame(width: labelWidth, alignment: .leading)

                            if let first_rev = store.factors_rev.first {
                                let firstBinding_rev = Binding<UnitFactor>(
                                    get: { store.factors_rev.first(where: { $0.id == first_rev.id }) ?? first_rev },
                                    set: { newValue in
                                        if let idx = store.factors_rev.firstIndex(where: { $0.id == first_rev.id }) {
                                            store.factors_rev[idx] = newValue
                                        }
                                    }
                                )
                                unitRow(for: firstBinding_rev)
                            } else {
                                Text("add units")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: rowHeight)

                        // Additional rows with ×
                        ForEach(store.factors_rev.dropFirst(), id: \.id) { factor in
                            let binding = Binding<UnitFactor>(
                                get: { store.factors_rev.first(where: { $0.id == factor.id }) ?? factor },
                                set: { newValue in
                                    if let idx = store.factors_rev.firstIndex(where: { $0.id == factor.id }) {
                                        store.factors_rev[idx] = newValue
                                    }
                                }
                            )
                            
                            HStack(alignment: .center, spacing: 12) {
                                Text("×")
                                    .font(.body)
                                    .frame(width: labelWidth, alignment: .center)
                                unitRow(for: binding)
                            }
                            .frame(height: rowHeight)
                        }
                    }
                    
                    HStack(spacing: 20) {
                        Button {
                            store.factors_rev.append(UnitFactor(prefixExp: 0, baseUnit: "m", unitExp: "0"))
                        } label: {
                            Label("Add unit", systemImage: "plus.circle")
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Clear") {
                            DispatchQueue.main.async {
                                store.factors_rev = []
                                store.valueStr_rev = "1.0"
                                store.inputUnitExp_rev = "1"
                                store.unit_result_rev = ""
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.red.opacity(0.8))
                        
                        Button("Convert") {
                                convertRight()
                            }
                        .buttonStyle(.borderedProminent)
                        
                    }
                    .padding(.top, 8)


                    if !store.unit_result_rev.isEmpty {
                        Text(store.unit_result_rev)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: 700, alignment: .center)
            .padding()
            .background()  // card style
        }
        .padding()
    }

    @ViewBuilder
    private func unitRow(for factor: Binding<UnitFactor>) -> some View {
        HStack(spacing: 9) {
            Picker("(", selection: factor.prefixExp) {
                ForEach(prefixes, id: \.exp) { p in
                    Text(p.symbol.isEmpty ? "" : p.symbol).tag(p.exp)
                }
            }
            //.labelsHidden()
            .frame(width: 60, height: rowHeight )
            .clipped()

            Picker("", selection: factor.baseUnit) {
                ForEach(Array(siBaseToNatural.keys).sorted(), id: \.self) { u in
                    Text(u).tag(u)
                }
            }
            .labelsHidden()
            .frame(width: 75, height: rowHeight )
            .clipped()
            Text(") ^")

            TextField("-", text: factor.unitExp)
                .textFieldStyle(.roundedBorder)
                .frame(width: 25, height: rowHeight )
                .multilineTextAlignment(.center)

            Button(role: .destructive) {
                let idToRemove = factor.wrappedValue.id   // capture ID first
                
                DispatchQueue.main.async {
                    store.factors.removeAll { $0.id == idToRemove }
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .frame(width: 5, height: rowHeight - 8)
            }
        }
    }

    private func convertLeft() {
        guard let value = Double(store.valueStr) else {
            store.unit_result = "Invalid value"
            return
        }

        var totalFactor: Double = 1.0
        var totalPower: Int = 0

        for f in store.factors {
            guard let exp = Int(f.unitExp.trimmingCharacters(in: CharacterSet.whitespaces)),
                  let base = siBaseToNatural[f.baseUnit] else {
                store.unit_result = "Invalid exponent or unit"
                return
            }
            
            // Input prefix: multiplies value
            if exp >= 0 {
                let inputPrefixFactor = pow(10.0, Double(f.prefixExp * exp))
                totalFactor *= inputPrefixFactor * pow(base.factor, Double(exp))
                totalPower += base.power * exp
            } else {
                let inputPrefixFactor = pow(10.0, -Double(f.prefixExp * exp))
                totalFactor *= inputPrefixFactor * pow(base.factor, Double(exp))
                totalPower += base.power * exp
            }
        }

        var numerical = value * totalFactor

        // Selected output prefix
        let outPrefix = prefixes.first { $0.exp == store.outputPrefixExp }!
        let outExp = outPrefix.exp

        // Dimensionless case
        if totalPower == 0 {
            // Scale down by output prefix
            numerical /= pow(10.0, Double(outExp))

            let fmt = abs(numerical) < 1e5 && abs(numerical) > 1e-5
                ? String(format: "%.6g", numerical)
                : String(format: "%.4e", numerical)

            let prefixPart = outPrefix.symbol.isEmpty ? "" : " \(outPrefix.symbol)"

            store.unit_result = "\(fmt)\(prefixPart)"
            return
        }

        // Non-dimensionless case: scale down to match chosen output unit
        numerical /= pow(10.0, Double(outExp) * Double(totalPower))

        // Select unit name based on output prefix
        var unitBase: String
        switch outExp {
        case 24: unitBase = "YeV"
        case 21: unitBase = "ZeV"
        case 18: unitBase = "EeV"
        case 15: unitBase = "PeV"
        case 12: unitBase = "TeV"
        case  9: unitBase = "GeV"
        case  6: unitBase = "MeV"
        case  3: unitBase = "keV"
        case  0: unitBase = "eV"
        case -3: unitBase = "meV"
        case -6: unitBase = "μeV"
        case -9: unitBase = "neV"
        case -12: unitBase = "feV"
        case -15: unitBase = "peV"
        case -18: unitBase = "aeV"
        default: unitBase = "eV"
        }

        let absPower = abs(totalPower)
        let powerPart = (absPower == 0 || totalPower == 1) ? "" : "^{\(totalPower)}"

        let mainFmt = abs(numerical) < 1e5 && abs(numerical) > 1e-5
            ? String(format: "%.6g", numerical)
            : String(format: "%.4e", numerical)

        var approxStr = ""
        if absPower > 0 {
            let rootNum = pow(numerical, 1.0 / Double(totalPower))
            let rootFmt = String(format: "%.3g", rootNum)
            approxStr = "  ≃  (\(rootFmt) \(unitBase))^{\(totalPower)}"
        }
        

        store.unit_result = "\(mainFmt) \(unitBase)\(powerPart)\n\(approxStr)"
    }
    
    private func convertRight() {
        guard let value = Double(store.valueStr_rev) else {
            store.unit_result_rev = "Invalid value"
            return
        }

        // (1) Calculate totalPower_rev from output factors
        var totalPower_rev: Int = 0
        var totalFactor_rev: Double = 1.0
        var totalUnit_rev: String = ""

        for f in store.factors_rev {
            guard let exp = Int(f.unitExp.trimmingCharacters(in: .whitespaces)),
                  let base = siBaseToNatural[f.baseUnit] else {
                store.unit_result_rev = "Invalid exponent or unit"
                return
            }

            let prefixFactor = pow(10.0, Double(f.prefixExp))
            let symbol_rev = prefixes.first { $0.exp == f.prefixExp }?.symbol ?? "—"
            totalFactor_rev *= pow(1/(base.factor * prefixFactor), Double(exp))
            totalPower_rev += base.power * exp
            totalUnit_rev += symbol_rev + f.baseUnit + "^{" + f.unitExp + "}" + " "
        }

        // Check dimension match
        guard let inputExp = Int(store.inputUnitExp_rev.trimmingCharacters(in: .whitespaces)),
              totalPower_rev == inputExp else {
            store.unit_result_rev = "Dimension mismatch!"
            return
        }

        // (2) Proceed with calculation if dimensions match
        let numerical = value * pow(10.0, Double(store.inputPrefixExp_rev * inputExp)) * totalFactor_rev


        // Basic formatting (you can reuse/improve the same style as convertLeft)
        let mainFmt = abs(numerical) < 1e5 && abs(numerical) > 1e-5
            ? String(format: "%.6g", numerical)
            : String(format: "%.4e", numerical)


        store.unit_result_rev = "\(mainFmt) " + totalUnit_rev
    }
}

#Preview {
    UnitConverterView_2()
}

