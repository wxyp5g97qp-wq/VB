import SwiftUI

/// Профиль администратора (аккаунт студии)
struct AdminProfileView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Профиль админа")
                    .typography(AppFont.lead1)
                    .foregroundColor(Color("W2"))
                    .padding(.top, 24)
                    .padding(.horizontal, 21)

                Text("Тут будет управление аккаунтом админа, студией, контактами и правами.")
                    .typography(AppFont.text)
                    .foregroundColor(Color("G3"))
                    .padding(.horizontal, 21)

                Spacer()
            }
        }
    }
}

#Preview {
    NavigationStack {
        AdminProfileView()
            .environmentObject(BookingFlowState())
    }
    .preferredColorScheme(.dark)
}
