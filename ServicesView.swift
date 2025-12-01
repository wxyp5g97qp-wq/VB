import SwiftUI

// MARK: - Модели услуг

struct ServiceCategory: Identifiable {
    let id = UUID()
    let title: String
    let services: [ServiceItem]
}

struct ServiceItem: Identifiable {
    let id = UUID()
    let title: String           // "Тонировка"
    let area: String            // "Передние стекла"
    let duration: String        // "60 минут"
    let price: String           // "4400 ₽"
    let imageName: String?      // имя картинки (потом подставишь)
}

// MARK: - Моки

enum ServicesMockData {
    static let categories: [ServiceCategory] = [
        ServiceCategory(
            title: "Тонировка",
            services: [
                ServiceItem(title: "Тонировка", area: "Передние стекла", duration: "60 минут", price: "4400 ₽", imageName: nil),
                ServiceItem(title: "Тонировка", area: "Передние стекла", duration: "60 минут", price: "4400 ₽", imageName: nil),
                ServiceItem(title: "Тонировка", area: "Передние стекла", duration: "60 минут", price: "4400 ₽", imageName: nil)
            ]
        ),
        ServiceCategory(
            title: "Бронеплёнка",
            services: [
                ServiceItem(title: "Бронеплёнка", area: "Передний бампер", duration: "3 часа", price: "15000 ₽", imageName: nil)
            ]
        ),
        ServiceCategory(
            title: "Полировка",
            services: [
                ServiceItem(title: "Полировка", area: "Кузов", duration: "1 день", price: "25000 ₽", imageName: nil)
            ]
        ),
        ServiceCategory(
            title: "Доп. услуги",
            services: [
                ServiceItem(title: "Химчистка салона", area: "Полный салон", duration: "4 часа", price: "8000 ₽", imageName: nil)
            ]
        ),
        ServiceCategory(
            title: "Акции",
            services: [
                ServiceItem(title: "Комплекс «Премиум»", area: "Кузов + салон", duration: "1 день", price: "по акции", imageName: nil)
            ]
        )
    ]
}

// MARK: - Экран «Услуги»

struct ServicesView: View {

    @EnvironmentObject var bookingFlow: BookingFlowState

    @State private var expandedCategoryId: UUID? = nil
    @State private var selectedServiceId: UUID? = nil

    @State private var showMasterSelection: Bool = false

    private let categories = ServicesMockData.categories

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Шапка
                VStack(alignment: .leading, spacing: 16) {
                    Text("Наши услуги")
                        .typography(AppFont.lead1)
                        .foregroundColor(Color("W2"))

                    Text("Конечная стоимость услуг зависит от вашего автомобиля и будет указана при подтверждении записи с администратором после звонка.")
                        .typography(AppFont.text)
                        .foregroundColor(Color("G3"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 21)
                .padding(.top, 4)
                .padding(.bottom, 16)

                // Категории
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(categories) { category in
                            ServiceCategoryBlock(
                                category: category,
                                isExpanded: expandedCategoryId == category.id,
                                expandedCategoryId: $expandedCategoryId,
                                selectedServiceId: $selectedServiceId,
                                onNextService: { service in
                                    // Сохраняем услугу в общем стейте
                                    bookingFlow.selectedService = service
                                    // При смене услуги чистим мастера и дату/время
                                    bookingFlow.resetMaster()
                                    showMasterSelection = true
                                }
                            )
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showMasterSelection) {
            MasterSelectionView()
                .environmentObject(bookingFlow)
        }
    }
}

// MARK: - Категория

struct ServiceCategoryBlock: View {
    let category: ServiceCategory
    let isExpanded: Bool

    @Binding var expandedCategoryId: UUID?
    @Binding var selectedServiceId: UUID?

    let onNextService: (ServiceItem) -> Void

    private var categoryBackground: Color {
        isExpanded ? Color("B1") : Color("B5")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Хедер категории
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedCategoryId = nil
                        selectedServiceId = nil
                    } else {
                        expandedCategoryId = category.id
                        selectedServiceId = nil
                    }
                }
            } label: {
                HStack {
                    Text(category.title)
                        .typography(AppFont.lead3)
                        .foregroundColor(Color("W2"))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundColor(Color("W2"))
                }
                .padding(.horizontal, 21)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color("G4").opacity(0.5))
                .frame(height: 1)

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(category.services) { service in
                        ServiceRow(
                            service: service,
                            isSelected: selectedServiceId == service.id,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    if selectedServiceId == service.id {
                                        selectedServiceId = nil
                                    } else {
                                        selectedServiceId = service.id
                                    }
                                }
                            },
                            onNext: {
                                onNextService(service)
                            }
                        )

                        if service.id != category.services.last?.id {
                            Rectangle()
                                .fill(Color("BackgroundPrimary"))
                                .frame(height: 4)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(categoryBackground)
    }
}

// MARK: - Одна услуга

struct ServiceRow: View {
    let service: ServiceItem
    let isSelected: Bool
    let onTap: () -> Void
    let onNext: () -> Void

    private var rowBackground: Color {
        isSelected ? Color("G4") : Color("B1")
    }

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 12) {

                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color("W2").opacity(0.8))
                        .frame(height: 130)
                        .padding(.top, 11)
                        .padding(.leading, 17)
                        .padding(.trailing, 55)

                    HStack(spacing: 12) {
                        Text(service.area)
                            .typography(AppFont.roll1)
                            .foregroundColor(Color("W2"))

                        Spacer()

                        Text(service.duration)
                            .typography(AppFont.icon)
                            .foregroundColor(Color("W2"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color("G5"))
                            )

                        Text("от \(service.price)")
                            .typography(AppFont.roll1)
                            .foregroundColor(Color("W2"))
                    }
                    .padding(.horizontal, 17)
                    .padding(.bottom, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            if isSelected {
                Button(action: onNext) {
                    Text("Далее")
                        .typography(AppFont.roll1)
                        .foregroundColor(Color("B4"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color("W2"))
                        )
                        .padding(.horizontal, 17)
                        .padding(.bottom, 8)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground)
    }
}
