import SwiftUI
import Combine

@main
struct VBunker31App: App {

    // Один общий объект состояния на всё приложение
    @StateObject private var bookingFlow = BookingFlowState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(bookingFlow)
                .preferredColorScheme(.dark)
        }
    }
}
