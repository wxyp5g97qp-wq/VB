import SwiftUI

// MARK: - Модель мастера

struct Master: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let role: String
    let nextDayLabel: String
    let timeSlots: [String]
}

// MARK: - Экран выбора мастера

struct MasterSelectionView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bookingFlow: BookingFlowState

    @State private var selectedMaster: Master? = nil
    @State private var goToBookingTime: Bool = false

    private let masters = MasterMockData.masters

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundPrimary")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(masters) { master in
                                MasterRowView(
                                    master: master,
                                    isSelected: selectedMaster?.id == master.id,
                                    onSelect: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if selectedMaster?.id == master.id {
                                                selectedMaster = nil
                                            } else {
                                                selectedMaster = master
                                            }
                                        }
                                    }
                                )

                                if master.id != masters.last?.id {
                                    Rectangle()
                                        .fill(Color("G4").opacity(0.35))
                                        .frame(height: 1)
                                }
                            }
                        }
                        .padding(.horizontal, 21)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                    }

                    Spacer(minLength: 0)

                    primaryButton
                        .padding(.horizontal, 21)
                        .padding(.bottom, 16)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $goToBookingTime) {
                // один общий source — дальше поведение решает BookingTimeView по роли
                BookingTimeView(source: .userFlowFromMaster)
                    .environmentObject(bookingFlow)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }

    // MARK: - Шапка

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image("icon_back")
                    .renderingMode(.template)
                    .foregroundColor(Color("W2"))
            }

            Text("Выберите мастера")
                .typography(AppFont.lead1)
                .foregroundColor(Color("W2"))

            Spacer()
        }
        .padding(.horizontal, 50)
        .padding(.top, 24)
    }

    // MARK: - Кнопка «Далее»

    private var primaryButton: some View {
        let enabled = selectedMaster != nil

        return Button {
            guard let master = selectedMaster else { return }
            // Сохраняем мастера в стейт
            bookingFlow.selectedMaster = master
            // При смене мастера очищаем дату/время
            bookingFlow.resetDateTime()
            // Переход на выбор времени
            goToBookingTime = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(enabled ? Color("W2") : Color("G4"))

                Text("Далее")
                    .typography(AppFont.lead2)
                    .foregroundColor(enabled ? Color("B4") : Color("W2"))
            }
            .frame(height: 64)
        }
        .disabled(!enabled)
    }
}

// MARK: - Строка мастера

struct MasterRowView: View {
    let master: Master
    let isSelected: Bool
    let onSelect: () -> Void

    private var rowBackground: Color {
        isSelected ? Color("B1") : Color("BackgroundPrimary")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {

                Circle()
                    .fill(Color("G4"))
                    .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text(master.name)
                        .typography(AppFont.lead3)
                        .foregroundColor(Color("W2"))

                    Text(master.role)
                        .typography(AppFont.roll2)
                        .foregroundColor(Color("G3"))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button(action: onSelect) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 26))
                        .foregroundColor(isSelected ? Color("W2") : Color("G3"))
                }
            }

            HStack(spacing: 4) {
                Text("Ближайшее время для записи")
                    .typography(AppFont.text)
                    .foregroundColor(Color("G3"))

                Text(master.nextDayLabel)
                    .typography(AppFont.text)
                    .foregroundColor(Color("W2"))
            }

            HStack(spacing: 12) {
                ForEach(master.timeSlots, id: \.self) { time in
                    Text(time)
                        .typography(AppFont.roll1)
                        .foregroundColor(Color("W2"))
                        .frame(minWidth: 70)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color("G4"))
                        )
                }
            }
        }
        .padding(16)
        .background(rowBackground)
    }
}

// MARK: - Моки

enum MasterMockData {
    static let masters: [Master] = [
        Master(
            name: "Дмитрий",
            role: "Мастер по тонировке и оклейке",
            nextDayLabel: "завтра:",
            timeSlots: ["11:00", "12:30", "18:00", "18:30", "20:00"]
        ),
        Master(
            name: "Евгений",
            role: "Мастер по полировке",
            nextDayLabel: "завтра:",
            timeSlots: ["11:00", "12:30", "18:00", "18:30", "20:00"]
        )
    ]
}
