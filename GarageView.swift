import SwiftUI

struct GarageView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(spacing: 0) {

                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {

                        if bookingFlow.cars.isEmpty {
                            VStack(spacing: 12) {
                                Text("У вас пока нет автомобилей")
                                    .typography(AppFont.text)
                                    .foregroundColor(Color("G3"))
                                    .padding(.top, 80)
                            }
                        } else {
                            ForEach(bookingFlow.cars) { car in
                                NavigationLink {
                                    CarEditView(car: car)
                                } label: {
                                    carCard(car)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        addCarButton
                            .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image("icon_back")
                    .renderingMode(.template)
                    .foregroundColor(Color("W2"))
            }

            Text("Гараж")
                .typography(AppFont.lead1)
                .foregroundColor(Color("W2"))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    // MARK: - Карточка авто

    private func carCard(_ car: CarItem) -> some View {
        HStack {
            Text(car.number)
                .typography(AppFont.lead3)
                .foregroundColor(Color("W2"))

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(Color("G3"))
                .font(.system(size: 18))
        }
        .padding(18)
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("B1"))
        )
    }

    // MARK: - Кнопка "Добавить авто"

    private var addCarButton: some View {
        NavigationLink {
            CarEditView(car: nil)
        } label: {
            Text("Добавить авто")
                .typography(AppFont.lead2)
                .foregroundColor(Color("B4"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("W2"))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        GarageView()
            .environmentObject(BookingFlowState())
    }
    .preferredColorScheme(.dark)
}
