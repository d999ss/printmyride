import SwiftUI

struct StyleSheet: View {
    @Binding var design: PosterDesign
    @Environment(\.dismiss) private var dismiss
    
    var pushUndo: (PosterDesign) -> Void = { _ in }
    
    var body: some View {
        NavigationView {
            List {
                Section("Presets") {
                    ForEach(StylePreset.allCases) { preset in
                        Button(preset.rawValue) {
                            pushUndo(design)
                            var copy = design
                            preset.apply(to: &copy)
                            design = copy
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                        .font(DesignTokens.FontToken.body)
                        .foregroundColor(DesignTokens.ColorToken.accent)
                    }
                }
                
                Section("Stroke") {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        HStack {
                            Text("Width")
                                .font(DesignTokens.FontToken.body)
                            Spacer()
                            Text("\(design.strokeWidthPt, specifier: "%.2f") pt")
                                .font(DesignTokens.FontToken.monoFootnote)
                                .foregroundStyle(DesignTokens.ColorToken.secondary)
                        }
                        
                        Slider(value: Binding(
                            get: { design.strokeWidthPt },
                            set: { newVal in pushUndo(design); design.strokeWidthPt = newVal }
                        ), in: 0.25...12)
                    }
                }
                Section("Line Caps") {
                    Picker("Cap", selection: Binding(
                        get: { design.lineCap },
                        set: { newVal in pushUndo(design); design.lineCap = newVal }
                    )) {
                        Text("Round")
                            .font(DesignTokens.FontToken.footnote)
                            .tag(PosterDesign.LineCap.round)
                        Text("Square")
                            .font(DesignTokens.FontToken.footnote)
                            .tag(PosterDesign.LineCap.square)
                        Text("Butt")
                            .font(DesignTokens.FontToken.footnote)
                            .tag(PosterDesign.LineCap.butt)
                    }.pickerStyle(.segmented)
                }
                
                Section("Shadow") {
                    Toggle("Enable shadow", isOn: Binding(
                        get: { design.dropShadowEnabled },
                        set: { newVal in pushUndo(design); design.dropShadowEnabled = newVal }
                    ))
                    .font(DesignTokens.FontToken.body)
                    
                    if design.dropShadowEnabled {
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            HStack {
                                Text("Radius")
                                    .font(DesignTokens.FontToken.body)
                                Spacer()
                                Text("\(Int(design.dropShadowRadius)) px")
                                    .font(DesignTokens.FontToken.monoFootnote)
                                    .foregroundStyle(DesignTokens.ColorToken.secondary)
                            }
                            
                            Slider(value: Binding(
                                get: { design.dropShadowRadius },
                                set: { newVal in pushUndo(design); design.dropShadowRadius = newVal }
                            ), in: 0...30)
                        }
                    }
                }
                
                Section("Preview") {
                    PreviewStrip(design: design)
                        .frame(height: 60)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                }
            }
            .navigationTitle("Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(DesignTokens.FontToken.body)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        dismiss()
                    }
                    .font(DesignTokens.FontToken.title)
                    .foregroundColor(DesignTokens.ColorToken.accent)
                }
            }
        }
        .presentationDetents([.fraction(0.33), .fraction(0.66), .large])
        .presentationDragIndicator(.visible)
    }
}

struct PreviewStrip: View {
    let design: PosterDesign
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                design.backgroundColor.color
                
                Path { path in
                    let width = geo.size.width
                    let height = geo.size.height
                    let margin: CGFloat = 20
                    
                    path.move(to: CGPoint(x: margin, y: height / 2))
                    path.addLine(to: CGPoint(x: width - margin, y: height / 2))
                }
                .stroke(design.routeColor.color, lineWidth: design.strokeWidthPt)
            }
        }
        .cornerRadius(DesignTokens.Radius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                .stroke(DesignTokens.Colors.separator, lineWidth: 0.5)
        )
    }
}
