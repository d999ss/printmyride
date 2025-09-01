import SwiftUI

struct TextSheet: View {
    @Binding var text: PosterText
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: $text.title)
                        .font(DesignTokens.Typography.body)
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        HStack {
                            Text("Size")
                                .font(DesignTokens.Typography.body)
                            Spacer()
                            Text("\(Int(text.titleSizePt)) pt")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(DesignTokens.Colors.secondary)
                        }
                        Slider(value: $text.titleSizePt, in: 18...48)
                    }
                }
                
                Section("Subtitle") {
                    TextField("Subtitle", text: $text.subtitle)
                        .font(DesignTokens.Typography.body)
                }
                
                Section("Stats") {
                    Toggle("Show distance", isOn: $text.showDistance)
                        .font(DesignTokens.Typography.body)
                    Toggle("Show elevation", isOn: $text.showElevation)
                        .font(DesignTokens.Typography.body)
                    Toggle("Show date", isOn: $text.showDate)
                        .font(DesignTokens.Typography.body)
                }
            }
            .navigationTitle("Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(DesignTokens.Typography.body)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        dismiss()
                    }
                    .font(DesignTokens.Typography.title)
                    .foregroundColor(DesignTokens.Colors.accent)
                }
            }
        }
        .presentationDetents([.fraction(0.33), .fraction(0.66), .large])
        .presentationDragIndicator(.visible)
    }
}