import SwiftUI

struct VSCOPrimaryBar: View {
    let title: String; let action: () -> Void
    var body: some View {
        Button(action: { UISelectionFeedbackGenerator().selectionChanged(); action() }) {
            Text(title).font(.system(size:17, weight:.semibold)).foregroundStyle(.white)
                .frame(maxWidth:.infinity).frame(height:48)
                .background(Color(red:0xFC/255, green:0x4C/255, blue:0x02/255))
        }.buttonStyle(.plain).tint(nil)
    }
}

struct VSCOSecondaryBar: View {
    let title: String; let action: () -> Void
    var body: some View {
        Button(action: { UISelectionFeedbackGenerator().selectionChanged(); action() }) {
            ZStack { Rectangle().stroke(.white, lineWidth:1)
                Text(title).font(.system(size:17, weight:.semibold)).foregroundStyle(.white)
            }
            .frame(maxWidth:.infinity).frame(height:48)
        }.buttonStyle(.plain).tint(nil)
    }
}

struct VSCODestructiveRow: View {
    let leftTitle: String
    let rightTitle: String
    let leftAction: () -> Void
    let rightAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                UISelectionFeedbackGenerator().selectionChanged()
                leftAction()
            }) {
                Text(leftTitle)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.clear)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .tint(nil)
            .accessibilityLabel(Text(leftTitle))
            
            Button(action: {
                UISelectionFeedbackGenerator().selectionChanged()
                rightAction()
            }) {
                Text(rightTitle)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(red: 0xFC/255, green: 0x4C/255, blue: 0x02/255))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .tint(nil)
            .accessibilityLabel(Text(rightTitle))
        }
    }
}