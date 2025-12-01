import SwiftUI

// MARK: - Вкладки админского таббара

enum AdminTab: Int {
    case posts      // Посты (работы / акции / отзывы)
    case services   // Услуги
    case bookings   // Записи
    case summary    // Сводка
    case profile    // Профиль админа
}

// MARK: - Корневой экран админ-панели с нижним таббаром

struct AdminTabView: View {
    @State private var selectedTab: AdminTab = .posts

    var body: some View {
        VStack(spacing: 0) {

            // Контент текущей вкладки
            Group {
                switch selectedTab {
                case .posts:
                    AdminPostsView()
                case .services:
                    AdminServicesView()
                case .bookings:
                    AdminBookingsView()
                case .summary:
                    AdminSummaryView()
                case .profile:
                    AdminProfileView()
                }
            }
            .frame(maxWidth: .infinity,
                   maxHeight: .infinity,
                   alignment: .top)

            // Нижний таббар
            AdminTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Кастомный нижний TabBar для админа

struct AdminTabBar: View {
    @Binding var selectedTab: AdminTab

    var body: some View {
        HStack(spacing: 0) {
            tabButton(
                tab: .posts,
                title: "Посты",
                systemIcon: "doc.richtext"
            )
            tabButton(
                tab: .services,
                title: "Услуги",
                systemIcon: "wrench.and.screwdriver"
            )
            tabButton(
                tab: .bookings,
                title: "Записи",
                systemIcon: "calendar"
            )
            tabButton(
                tab: .summary,
                title: "Сводка",
                systemIcon: "chart.bar.xaxis"
            )
            tabButton(
                tab: .profile,
                title: "Профиль",
                systemIcon: "person.crop.circle"
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color("B1"))
    }

    private func tabButton(tab: AdminTab, title: String, systemIcon: String) -> some View {
        let isSelected = (tab == selectedTab)
        let color = isSelected ? Color("W2") : Color("G3")

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 22)
                    .foregroundColor(color)

                Text(title)
                    .typography(AppFont.text)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdminTabView()
    }
    .environmentObject(BookingFlowState())
    .preferredColorScheme(.dark)
}
