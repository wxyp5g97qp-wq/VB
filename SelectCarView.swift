import SwiftUI

struct SelectCarView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bookingFlow: BookingFlowState

    @State private var selectedCarId: UUID? = nil
    @State private var goToSummary: Bool = false

    // Берём список машин из общего стейта
    private var cars: [CarItem] {
        bookingFlow.cars
    }

    private var selectedCar: CarItem? {
        cars.first { $0.id == selectedCarId }
    }

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header
                addCarButton
                carList

                Spacer()

                nextButton
            }
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // если машина уже выбрана — подсветим её
            if let current = bookingFlow.selectedCar {
                selectedCarId = current.id
            }
        }
        // Переход к BookingSummaryView для пользователя
        .navigationDestination(isPresented: $goToSummary) {
            BookingSummaryView(
                onSuccess: {
                    // после успешной записи — переключаемся на вкладку "Мои записи"
                    bookingFlow.selectedTab = .records
                }
            )
            .environmentObject(bookingFlow)
            .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Шапка

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image("icon_back")
                    .renderingMode(.template)
                    .foregroundColor(Color("W2"))
            }

            Text("Выберите авто")
                .typography(AppFont.lead1)
                .foregroundColor(Color("W2"))

            Spacer()
        }
        .padding(.top, 24)
    }

    // MARK: - Добавить авто

    private var addCarButton: some View {
        NavigationLink {
            CarEditView(car: nil)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color("B1"))

                Text("Добавить Авто")
                    .typography(AppFont.lead3)
                    .foregroundColor(Color("W2"))

                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("W2"))
                    Spacer()
                }
                .padding(.leading, 20)
            }
            .frame(height: 56)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Список авто

    private var carList: some View {
        VStack(spacing: 14) {
            ForEach(cars) { car in
                HStack(spacing: 12) {
                    Text(car.number)
                        .typography(AppFont.lead2)
                        .foregroundColor(Color("B4"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color("W2"))
                        .cornerRadius(12)

                    Button {
                        selectedCarId = car.id
                        bookingFlow.selectedCar = car
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedCarId == car.id ? Color("W2") : Color("G4"))
                                .frame(width: 90, height: 56)

                            if selectedCarId == car.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color("B4"))
                            } else {
                                Text("Выбрать")
                                    .typography(AppFont.roll1)
                                    .foregroundColor(Color("W2"))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Кнопка «Далее»

    private var nextButton: some View {
        let enabled = selectedCar != nil

        return Button {
            guard let car = selectedCar else { return }
            bookingFlow.selectedCar = car
            goToSummary = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(enabled ? Color("W2") : Color("G4"))

                Text("Далее")
                    .typography(AppFont.lead2)
                    .foregroundColor(enabled ? Color("B4") : Color("W2"))
            }
            .frame(height: 64)
        }
        .disabled(!enabled)
        .padding(.bottom, 40)
    }
}

#Preview {
    NavigationStack {
        SelectCarView()
            .environmentObject(BookingFlowState())
            .preferredColorScheme(.dark)
    }
}
