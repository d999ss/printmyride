import SwiftUI

struct StravaInfoSheet: View {
    let message: String; let onClose: () -> Void
    var body: some View {
        ZStack { Color.black.ignoresSafeArea()
            VStack(spacing:16) {
                Text("Connect to Strava").font(.title3).bold().foregroundStyle(.white)
                Text(message).multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7)).padding(.horizontal,24)
                VSCOPrimaryBar(title:"Close", action:onClose).padding(.horizontal,16)
            }.padding(24)
        }
    }
}