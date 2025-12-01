import SwiftUI

struct RootView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState

    /// Пока true — показываем Splash
    @State private var showSplash: Bool = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .onAppear {
                        // Имитация короткой задержки сплеша
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
            } else {
                // После сплеша решаем, какой экран показать
                contentAfterSplash
            }
        }
        // 🔥 DEBUG-кнопка переключения роли (USER / ADMIN)
        .overlay(alignment: .bottomTrailing) {
            #if DEBUG
            roleDebugButton
            #endif
        }
    }

    /// Логика: если не залогинен → LoginView,
    /// если логин есть, но профиль не заполнен → ProfileFormView,
    /// иначе:
    ///   - для user  → MainTabView
    ///   - для admin → AdminTabView
    private var contentAfterSplash: some View {
        Group {
            if !bookingFlow.isLoggedIn {
                LoginView()
            } else if !bookingFlow.isProfileCompleted {
                ProfileFormView()
            } else {
                NavigationStack {
                    if bookingFlow.userRole == .admin {
                        AdminTabView()
                    } else {
                        MainTabView()
                    }
                }
            }
        }
    }

    // MARK: - DEBUG переключатель роли

    #if DEBUG
    private var roleDebugButton: some View {
        Button {
            withAnimation {
                bookingFlow.userRole = (bookingFlow.userRole == .admin) ? .user : .admin
            }
        } label: {
            Text(bookingFlow.userRole == .admin ? "ADMIN" : "USER")
                .font(.caption2.bold())          // можно заменить на твою типографику
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.25))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.trailing, 16)
        .padding(.bottom, 28)
    }
    #endif
}

#Preview {
    RootView()
        .environmentObject(BookingFlowState())
        .preferredColorScheme(.dark)
}
