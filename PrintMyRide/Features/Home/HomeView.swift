import SwiftUI
import CoreLocation

struct HomeView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var samplePayload: RoutePayload?
    @State private var showingEditor = false
    @State private var showStravaSheet = false
    @State private var stravaMessage: String?

    var body: some View {
        ZStack { Color.black.ignoresSafeArea()
            VStack(spacing:0) {
                // top-right close → dashboard (Create tab)
                HStack {
                    Spacer()
                    Button { router.selectedTab = 1 } label: {
                        Image(systemName:"xmark").font(.system(size:18,weight:.semibold))
                    }.foregroundStyle(.white).padding(.horizontal,16)
                }.frame(height:44)

                Spacer()
                
                CenterlineHeadline(text:"The Art of the Journey", wrapFactor:0.75, fontSize:45)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40) // Closer to CTA bar
            }
        }
        .safeAreaInset(edge:.bottom) {
            VStack(spacing:16) {
                VSCOPrimaryBar(title:"Connect to Strava") { startStravaConnect() }
                VSCOSecondaryBar(title:"See Example") { trySample() }
            }
            .padding(.horizontal,16).padding(.top,12)
            .padding(.bottom, max(16, safeBottomInset()))
            .background(Color.black)
            .overlay(Divider().background(.white.opacity(0.12)), alignment:.top)
        }
        .sheet(isPresented: $showStravaSheet) {
            StravaInfoSheet(message: stravaMessage ?? "We'll open Strava to authorize PMR, then you can pick a recent ride.",
                            onClose: { showStravaSheet = false })
        }
        .fullScreenCover(isPresented: $showingEditor) {
            if let p = samplePayload {
                PosterHost(payload: p) { showingEditor = false }
            } else {
                // Fallback to generated sample if somehow payload is nil
                PosterHost(payload: SampleRouteFactory.make()) { showingEditor = false }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    private func startStravaConnect() {
        Task {
            do {
                // When ready to wire: set clientId and backend URL in StravaService
                _ = try await StravaService.shared.connect()
                // Once connected, could fetch activities:
                // let acts = try await StravaService.shared.fetchActivities()
                // showActivityPicker(acts)
                stravaMessage = "Connected successfully!"
                showStravaSheet = true
            } catch {
                // Until OAuth is wired, show friendly instructions
                stravaMessage = "Strava isn't connected yet. Add your Client ID and backend URLs in StravaService, then tap Connect again."
                showStravaSheet = true
            }
        }
    }

    private func trySample() {
        samplePayload = SampleRouteFactory.make()
        showingEditor = true
    }

    
    private func safeBottomInset() -> CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .keyWindow?.safeAreaInsets.bottom ?? 0
    }
}