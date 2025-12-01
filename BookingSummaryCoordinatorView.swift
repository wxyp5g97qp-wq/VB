import SwiftUI

/// Обертка над экраном проверки данных.
/// Нужна, чтобы после успешной записи:
///  1) перейти на вкладку "Мои записи"
///  2) закрыть экран проверки данных.
struct BookingSummaryCoordinatorView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        BookingSummaryView {
            // Переходим на вкладку "Записи"
            bookingFlow.selectedTab = .records
            // Закрываем экран проверки данных
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        BookingSummaryCoordinatorView()
            .environmentObject(BookingFlowState())
    }
    .preferredColorScheme(.dark)
}
