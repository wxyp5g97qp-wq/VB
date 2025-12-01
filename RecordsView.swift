import SwiftUI

struct RecordsView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState

    @State private var showCancelAlert: Bool = false
    @State private var bookingToCancel: Booking? = nil

    // Формат "02 ноября"
    private static let dayMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "dd MMMM"
        return f
    }()

    // Формат "24 января 2025 года"
    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "dd MMMM yyyy года"
        return f
    }()

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Заголовок
                Text("Мои записи")
                    .typography(AppFont.lead1)
                    .foregroundColor(Color("W2"))
                    .padding(.top, 24)
                    .padding(.horizontal, 21)

                let upcoming = upcomingBookings
                let past = pastBookings

                if upcoming.isEmpty && past.isEmpty {
                    Spacer()
                    Text("У вас пока нет записей")
                        .typography(AppFont.text)
                        .foregroundColor(Color("G3"))
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {

                            // Актуальные
                            if !upcoming.isEmpty {
                                sectionTitle("Актуальные")
                                    .padding(.horizontal, 21)

                                VStack(spacing: 16) {
                                    ForEach(upcoming) { booking in
                                        upcomingCard(booking)
                                    }
                                }
                                .padding(.horizontal, 21)
                            }

                            // Прошедшие
                            if !past.isEmpty {
                                sectionTitle("Прошедшие")
                                    .padding(.horizontal, 21)

                                VStack(spacing: 16) {
                                    ForEach(past) { booking in
                                        pastCard(booking)
                                    }
                                }
                                .padding(.horizontal, 21)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .alert("Вы действительно хотите отменить запись?",
               isPresented: $showCancelAlert) {
            Button("Нет", role: .cancel) {
                bookingToCancel = nil
            }
            Button("Да", role: .destructive) {
                if let booking = bookingToCancel {
                    bookingFlow.cancelBooking(booking)
                }
                bookingToCancel = nil
            }
        } message: {
            Text("После отмены запись нельзя будет восстановить.")
        }
    }

    // MARK: - Разделение записей

    private var upcomingBookings: [Booking] {
        let today = Calendar.current.startOfDay(for: Date())
        return bookingFlow.bookings
            .filter { $0.date >= today }
            .sorted { $0.date < $1.date }
    }

    private var pastBookings: [Booking] {
        let today = Calendar.current.startOfDay(for: Date())
        return bookingFlow.bookings
            .filter { $0.date < today }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Заголовок секции

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .typography(AppFont.lead3)
            .foregroundColor(Color("W2"))
            .padding(.bottom, 4)
            .overlay(
                Rectangle()
                    .fill(Color("W2"))
                    .frame(height: 2),
                alignment: .bottomLeading
            )
    }

    // MARK: - Карточка актуальной записи (верхняя часть макета)

    private func upcomingCard(_ booking: Booking) -> some View {
        HStack(spacing: 12) {
            // Основной блок
            VStack(alignment: .leading, spacing: 10) {
                // Услуга
                Text(booking.serviceTitle)
                    .typography(AppFont.lead3)
                    .foregroundColor(Color("B4"))

                // Номер + дата/время
                HStack {
                    Text(booking.carPlate)
                        .typography(AppFont.roll1)
                        .foregroundColor(Color("B4"))

                    Spacer()

                    let dateString = RecordsView.dayMonthFormatter.string(from: booking.date)
                    Text("\(dateString) в \(booking.time)")
                        .typography(AppFont.text)
                        .foregroundColor(Color("G3"))
                }

                // Статус + цена (пока заглушка)
                HStack {
                    Text(booking.status == .cancelled ? "Отменена" : "Подтверждена")
                        .typography(AppFont.roll1)
                        .foregroundColor(Color("B4"))

                    Spacer()

                    Text("6000 ₽") // TODO: позже подставлять реальную цену
                        .typography(AppFont.roll1)
                        .foregroundColor(Color("B4"))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("W2"))
            )

            // Правая колонка кнопок
            VStack(spacing: 12) {
                if booking.status == .cancelled {
                    // Только неактивная "Отменена"
                    Text("Отменена")
                        .typography(AppFont.roll1)
                        .foregroundColor(Color("W2"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("B1"))
                        )
                } else {
                    // "Отменить"
                    Button {
                        bookingToCancel = booking
                        showCancelAlert = true
                    } label: {
                        Text("Отменить")
                            .typography(AppFont.roll1)
                            .foregroundColor(Color("W2"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("B1"))
                            )
                    }
                    .buttonStyle(.plain)

                    // "Связаться"
                    Button {
                        // TODO: здесь позже повесим звонок администратору
                        print("Связаться по записи \(booking.id)")
                    } label: {
                        Text("Связаться")
                            .typography(AppFont.roll1)
                            .foregroundColor(Color("B4"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("W2"))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 118)
        }
    }

    // MARK: - Карточка прошедшей записи (нижние блоки)

    private func pastCard(_ booking: Booking) -> some View {
        HStack(spacing: 12) {
            // Левая "плашка" с услугой и датой
            VStack(alignment: .leading, spacing: 8) {
                Text("Запись на \(booking.serviceTitle)")
                    .typography(AppFont.roll1)
                    .foregroundColor(Color("B4"))

                let fullDate = RecordsView.fullDateFormatter.string(from: booking.date)
                Text(fullDate)
                    .typography(AppFont.text)
                    .foregroundColor(Color("G3"))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("W2"))
            )

            // Правая кнопка
            if booking.status == .cancelled {
                // Неактивная "Отменена"
                Text("Отменена")
                    .typography(AppFont.roll1)
                    .foregroundColor(Color("W2"))
                    .frame(width: 96, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("B1"))
                    )
            } else {
                NavigationLink {
                    ReviewFormView(booking: booking)
                } label: {
                    Text("Отзыв")
                        .typography(AppFont.roll1)
                        .foregroundColor(Color("W2"))
                        .frame(width: 96, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("B1"))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecordsView()
            .environmentObject(BookingFlowState())
    }
    .preferredColorScheme(.dark)
}
