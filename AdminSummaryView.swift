import SwiftUI

/// Сводка по выручке, загрузке, статистикам (пока заглушка)
struct AdminSummaryView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Сводка")
                    .typography(AppFont.lead1)
                    .foregroundColor(Color("W2"))
                    .padding(.top, 24)
                    .padding(.horizontal, 21)

                Text("Здесь позже добавим графики по выручке, загрузке по дням, конверсии и т.п.")
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
        AdminSummaryView()
            .environmentObject(BookingFlowState())
    }
    .preferredColorScheme(.dark)
}
