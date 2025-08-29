import SwiftUI

struct TextSheet: View {
    @Binding var text: PosterText
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: $text.title)
                        .font(DesignTokens.FontToken.body)
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        HStack {
                            Text("Size")
                                .font(DesignTokens.FontToken.body)
                            Spacer()
                            Text("\(Int(text.titleSizePt)) pt")
                                .font(DesignTokens.FontToken.monoFootnote)
                                .foregroundStyle(DesignTokens.ColorToken.secondary)
                        }
                        Slider(value: $text.titleSizePt, in: 18...48)
                    }
                }
                
                Section("Subtitle") {
                    TextField("Subtitle", text: $text.subtitle)
                        .font(DesignTokens.FontToken.body)
                }
                
                Section("Stats") {
                    Toggle("Show distance", isOn: $text.showDistance)
                        .font(DesignTokens.FontToken.body)
                    Toggle("Show elevation", isOn: $text.showElevation)
                        .font(DesignTokens.FontToken.body)
                    Toggle("Show date", isOn: $text.showDate)
                        .font(DesignTokens.FontToken.body)
                }
            }
            .navigationTitle("Text")
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