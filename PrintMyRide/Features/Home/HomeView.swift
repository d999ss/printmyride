import SwiftUI
import CoreLocation

private struct HomeBackground: View {
    var body: some View {
        GeometryReader { proxy in
            Image("Art of the Journey 1")
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .ignoresSafeArea()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct HomeView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var samplePayload: RoutePayload?
    @State private var showingEditor = false
    @State private var showStravaSheet = false
    @State private var stravaMessage: String?
    @State private var showStravaError = false
    @State private var stravaErrorText = ""

    var body: some View {
        ZStack {
            // 0) Fallback
            Color.black.ignoresSafeArea()

            // 1) Background image (fades to transparent at bottom)
            GeometryReader { proxy in
                Image("Art of the Journey 1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .white,  location: 0.00),
                                .init(color: .white,  location: 0.78),
                                .init(color: .clear,  location: 1.00)
                            ]),
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            // 3) Your original content (unchanged)
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { router.selectedTab = 2 } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                }
                .frame(height: 44)

                Spacer()

                CenterlineHeadline(text: "The Art of the Journey",
                                   wrapFactor: 0.75,
                                   fontSize: 45)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)   // was 40 → moves it ~8pt closer to the CTA
                    .offset(y: 8)           // visually drop the headline ~8pt
            }
        }
        .safeAreaInset(edge:.bottom) {
            VStack(spacing:16) {
                VSCOPrimaryBar(title:"Connect to Strava") { 
                    Task { await connectStrava() }
                }
                VSCOSecondaryBar(title:"See Example") { trySample() }
            }
            .padding(.horizontal,16).padding(.top,12)
            .padding(.bottom, max(16, safeBottomInset()))
            .background(Color.clear)
        }
        .sheet(isPresented: $showStravaSheet) {
            StravaInfoSheet(message: stravaMessage ?? "We'll open Strava to authorize PMR, then you can pick a recent ride.",
                            onClose: { showStravaSheet = false })
        }
        .fullScreenCover(isPresented: $showingEditor) {
            if let p = samplePayload {
                PosterHost(payload: p) { 
                    showingEditor = false
                    router.selectedTab = 0  // Navigate to Home tab
                }
            } else {
                // Fallback to generated sample if somehow payload is nil
                PosterHost(payload: SampleRouteFactory.make()) { 
                    showingEditor = false
                    router.selectedTab = 0  // Navigate to Home tab
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .alert("Strava", isPresented: $showStravaError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(stravaErrorText.isEmpty ? "Couldn't connect to Strava." : stravaErrorText)
        }
    }

    private func connectStrava() async {
        do {
            _ = try await StravaService.shared.connect()
            // TODO: present activity picker next
        } catch PMRError.notConnected {
            stravaErrorText = "Strava isn't configured. Add STRAVA_CLIENT_ID and backend URLs in Info.plist."
            showStravaError = true
        } catch PMRError.badCallback {
            stravaErrorText = "Strava didn't return a code. Check pmr URL scheme and redirect."
            showStravaError = true
        } catch PMRError.http {
            stravaErrorText = "Token exchange failed. Check your backend /exchange endpoint."
            showStravaError = true
        } catch {
            stravaErrorText = error.localizedDescription
            showStravaError = true
        }
    }
    
    private func startStravaConnect() {
        Task { await connectStrava() }
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