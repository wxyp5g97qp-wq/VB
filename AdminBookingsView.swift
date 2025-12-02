import SwiftUI

// MARK: - Фильтр по дате

private enum AdminBookingDateFilter: String, CaseIterable {
    case today    = "Сегодня"
    case upcoming = "Ближайшие"
    case all      = "Все"
}

// MARK: - Основной экран

struct AdminBookingsView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState

    @State private var dateFilter: AdminBookingDateFilter = .today
    @State private var masterFilter: String? = nil

    /// IDs записей, по которым уже «связались»
    @State private var contactedIds: Set<UUID> = []

    /// Алерт подтверждения цены
    @State private var showPriceAlert = false
    @State private var priceInput: String = ""
    @State private var bookingForPrice: Booking?

    /// Алерт отмены
    @State private var showCancelAlert = false
    @State private var bookingForCancel: Booking?

    /// sheet «Добавить запись»
    @State private var showAddSheet = false

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                header

                filtersBar
                    .padding(.horizontal, 21)

                if filteredBookings.isEmpty {
                    Text("Записей нет.")
                        .typography(AppFont.text)
                        .foregroundColor(Color("G3"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 21)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            ForEach(filteredBookings) { booking in
                                AdminBookingCard(
                                    booking: booking,
                                    isContacted: contactedIds.contains(booking.id),
                                    onContact: {
                                        contactedIds.insert(booking.id)
                                    },
                                    onConfirm: {
                                        bookingForPrice = booking
                                        priceInput = booking.price.map { String($0) } ?? ""
                                        showPriceAlert = true
                                    },
                                    onCancel: {
                                        bookingForCancel = booking
                                        showCancelAlert = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 21)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        // MARK: - alert с вводом суммы
        .alert("Укажите предварительную сумму", isPresented: $showPriceAlert) {
            TextField("Например: 6000", text: $priceInput)
                .keyboardType(.numberPad)

            Button("Подтвердить") {
                guard let booking = bookingForPrice else { return }
                let digits = priceInput.filter { $0.isNumber }
                let value = Int(digits)
                bookingFlow.updateBookingPrice(value, for: booking)
            }

            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Сумма не окончательная и может быть изменена при осмотре машины.")
        }

        // MARK: - alert отмены
        .alert("Отменить запись?", isPresented: $showCancelAlert) {
            Button("Отменить запись", role: .destructive) {
                if let booking = bookingForCancel {
                    bookingFlow.cancelBooking(booking)
                    contactedIds.remove(booking.id)
                }
            }
            Button("Нет", role: .cancel) { }
        } message: {
            Text("Вы действительно хотите отменить запись?")
        }

        // MARK: - sheet добавления записи админом
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                BookingSummaryView {
                    // Это onSuccess из BookingSummaryView:
                    // закрываем модалку и остаёмся на экране "Записи"
                    showAddSheet = false
                }
                .environmentObject(bookingFlow)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Записи")
                .typography(AppFont.lead1)
                .foregroundColor(Color("W2"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
                .padding(.horizontal, 21)

            Button {
                showAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                    Text("Добавить запись")
                        .typography(AppFont.roll1)
                }
                .foregroundColor(Color("B4"))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("W2"))
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 21)
        }
    }

    // MARK: - Панель фильтров

    private var filtersBar: some View {
        HStack(spacing: 8) {

            // Фильтр по дате
            Menu {
                Picker("Дата", selection: $dateFilter) {
                    ForEach(AdminBookingDateFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
            } label: {
                HStack {
                    Text(dateFilter.rawValue)
                        .typography(AppFont.roll1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Color("W2"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color("B3"))
                )
            }

            // Фильтр по мастеру
            Menu {
                Button("Все мастера") {
                    masterFilter = nil
                }

                let masters = Set(bookingFlow.bookings.map { $0.masterName })
                    .sorted()

                ForEach(masters, id: \.self) { name in
                    Button(name) {
                        masterFilter = name
                    }
                }
            } label: {
                HStack {
                    Text(masterFilter ?? "Все мастера")
                        .typography(AppFont.roll1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Color("W2"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color("B3"))
                )
            }

            Spacer()
        }
    }

    // MARK: - Отфильтрованный список

    private var filteredBookings: [Booking] {
        let calendar = Calendar.current
        let today = Date()

        return bookingFlow.bookings
            .filter { booking in
                switch dateFilter {
                case .today:
                    return calendar.isDate(booking.date, inSameDayAs: today)
                case .upcoming:
                    return booking.date >= calendar.startOfDay(for: today)
                case .all:
                    return true
                }
            }
            .filter { booking in
                if let master = masterFilter {
                    return booking.masterName == master
                } else {
                    return true
                }
            }
            .sorted { $0.date < $1.date }
    }
}

// MARK: - Карточка записи для админа

private struct AdminBookingCard: View {
    let booking: Booking
    let isContacted: Bool
    let onContact: () -> Void
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "dd MMMM в HH:mm"
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {

            // Левая часть — карточка записи (как у пользователя)
            VStack(alignment: .leading, spacing: 6) {
                Text(booking.serviceTitle)
                    .typography(AppFont.roll1)
                    .foregroundColor(Color("B4"))

                if let phone = booking.clientPhone, !phone.isEmpty {
                    Text(phone)
                        .typography(AppFont.subtitle)
                        .foregroundColor(Color("W2"))
                }

                Text(Self.dateFormatter.string(from: booking.date))
                    .typography(AppFont.icon)
                    .foregroundColor(Color("G3"))

                Text(statusTitle)
                    .typography(AppFont.subtitle)
                    .foregroundColor(statusColor)

                Text(priceText)
                    .typography(AppFont.subtitle)
                    .foregroundColor(Color("W2"))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("W2"))
            )

            // Правая колонка кнопок
            VStack(spacing: 8) {

                Button {
                    onConfirm()
                } label: {
                    Text("Подтвердить")
                        .typography(AppFont.roll1)
                        .foregroundColor(Color("B4"))
                        .frame(width: 110, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("W2"))
                        )
                }
                .buttonStyle(.plain)

                Button {
                    onContact()
                } label: {
                    Text("Связаться")
                        .typography(AppFont.roll1)
                        .foregroundColor(Color("W2"))
                        .frame(width: 110, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("B3"))
                        )
                }
                .buttonStyle(.plain)

                if isContacted {
                    Button {
                        onCancel()
                    } label: {
                        Text("Отменить")
                            .typography(AppFont.roll1)
                            .foregroundColor(Color("W2"))
                            .frame(width: 110, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("B1"))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var statusTitle: String {
        switch booking.status {
        case .active:
            return "Подтверждена"
        case .cancelled:
            return "Отменена"
        case .completed:
            return "Завершена"
        }
    }

    private var statusColor: Color {
        switch booking.status {
        case .active:    return Color("B4")
        case .cancelled: return .red
        case .completed: return Color("G3")
        }
    }

    private var priceText: String {
        if let price = booking.price {
            return "\(price) ₽"
        } else {
            return "Сумма не указана"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdminBookingsView()
            .environmentObject(BookingFlowState())
    }
    .preferredColorScheme(.dark)
}
