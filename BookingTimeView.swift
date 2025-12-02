import SwiftUI

// MARK: - Откуда открыт экран выбора даты/времени

enum BookingTimeSource {
    /// Открыт после выбора мастера (новый флоу записи)
    case fromMaster

    /// Открыт из экрана BookingSummaryView для редактирования даты/времени
    case fromSummary
}

// MARK: - Экран «Выберите время»

struct BookingTimeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bookingFlow: BookingFlowState

    let source: BookingTimeSource

    // Удобный init: по умолчанию считаем, что пришли «после мастера»
    init(source: BookingTimeSource = .fromMaster) {
        self.source = source
    }

    @State private var currentMonthIndex: Int = 0
    @State private var selectedDate: Date? = nil
    @State private var selectedTime: String? = nil
    @State private var expandedParts: Set<PartOfDay> = Set(PartOfDay.allCases)

    /// Навигация вперёд:
    /// - для пользователя — к SelectCarView
    /// - для админа — к BookingSummaryView
    @State private var goToUserCarSelection: Bool = false
    @State private var goToAdminSummary: Bool = false

    private let calendar = BookingCalendarMock.calendar
    private let months = BookingCalendarMock.months

    private let timeSlots: [PartOfDay: [String]] = [
        .morning: ["09:00", "09:30", "10:00", "11:30"],
        .day:     ["14:00", "15:30", "16:00"],
        .evening: ["18:00", "19:30"]
    ]

    private var currentMonth: BookingCalendarMonth {
        months[currentMonthIndex]
    }

    private var isFormValid: Bool {
        selectedDate != nil && selectedTime != nil
    }

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                header
                monthPickerRow

                CalendarMonthView(
                    month: currentMonth,
                    selectedDate: $selectedDate
                )
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 21)

                legend

                VStack(spacing: 16) {
                    ForEach(PartOfDay.allCases, id: \.self) { part in
                        TimeSectionView(
                            part: part,
                            times: timeSlots[part] ?? [],
                            isExpanded: expandedParts.contains(part),
                            selectedTime: $selectedTime,
                            toggleExpanded: {
                                if expandedParts.contains(part) {
                                    expandedParts.remove(part)
                                } else {
                                    expandedParts.insert(part)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 21)

                Spacer(minLength: 0)

                Button {
                    confirmTime()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isFormValid ? Color("W2") : Color("G4"))

                        Text("Далее")
                            .typography(AppFont.lead2)
                            .foregroundColor(isFormValid ? Color("B4") : Color("W2"))
                    }
                    .frame(height: 64)
                }
                .disabled(!isFormValid)
                .padding(.horizontal, 21)
                .padding(.bottom, 60)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: selectedDate) { _, _ in
            selectedTime = nil
        }
        .onAppear {
            // подтягиваем уже выбранные дату/время, если они есть
            selectedDate = bookingFlow.selectedDate
            selectedTime = bookingFlow.selectedTime
        }
        // Навигация дальше — только когда мы пришли "после мастера"
        .navigationDestination(isPresented: $goToUserCarSelection) {
            SelectCarView()
                .environmentObject(bookingFlow)
        }
        .navigationDestination(isPresented: $goToAdminSummary) {
            BookingSummaryView()
                .environmentObject(bookingFlow)
        }
    }

    // MARK: - Логика подтверждения времени

    private func confirmTime() {
        guard isFormValid,
              let date = selectedDate,
              let time = selectedTime else { return }

        // сохраняем выбор в общий стейт
        bookingFlow.selectedDate = date
        bookingFlow.selectedTime = time

        switch source {
        case .fromMaster:
            // Новый флоу: дальше действия зависят от роли
            switch bookingFlow.userRole {
            case .user:
                // Пользователь — дальше выбирает авто
                goToUserCarSelection = true
            case .admin:
                // Админ — сразу на общий Summary с телефоном
                goToAdminSummary = true
            }

        case .fromSummary:
            // Редактирование из Summary — просто возвращаемся назад
            dismiss()
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

            Text("Выберите время")
                .typography(AppFont.lead1)
                .foregroundColor(Color("W2"))

            Spacer()
        }
        .padding(.horizontal, 21)
        .padding(.top, 24)
    }

    // MARK: - Кнопка выбора месяца

    private var monthPickerRow: some View {
        HStack {
            Menu {
                ForEach(months.indices, id: \.self) { index in
                    Button(months[index].title) {
                        currentMonthIndex = index
                        selectedDate = nil
                        selectedTime = nil
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentMonth.title)
                        .typography(AppFont.roll1)
                        .foregroundColor(Color("B4"))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("B4"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("W2"))
                )
            }

            Spacer()
        }
        .padding(.horizontal, 21)
    }

    // MARK: - Легенда

    private var legend: some View {
        HStack(spacing: 24) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color("R1"))
                    .frame(width: 10, height: 10)

                Text("Запись закрыта")
                    .typography(AppFont.roll1)
                    .foregroundColor(Color("G3"))
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(Color("W2"))
                    .frame(width: 10, height: 10)

                Text("Дата выбрана")
                    .typography(AppFont.roll1)
                    .foregroundColor(Color("G3"))
            }

            Spacer()
        }
        .padding(.horizontal, 21)
    }
}

// MARK: - Части дня

enum PartOfDay: String, CaseIterable {
    case morning = "Утро"
    case day     = "День"
    case evening = "Вечер"
}

// MARK: - Секция времени (Утро/День/Вечер)

struct TimeSectionView: View {
    let part: PartOfDay
    let times: [String]
    let isExpanded: Bool

    @Binding var selectedTime: String?
    let toggleExpanded: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Button(action: toggleExpanded) {
                HStack {
                    Text(part.rawValue)
                        .typography(AppFont.lead3)
                        .foregroundColor(Color("W2"))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundColor(Color("W2"))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                HStack(spacing: 12) {
                    ForEach(times, id: \.self) { time in
                        let isSelected = (time == selectedTime)

                        Button {
                            selectedTime = isSelected ? nil : time
                        } label: {
                            Text(time)
                                .typography(AppFont.roll1)
                                .foregroundColor(isSelected ? Color("B4") : Color("W2"))
                                .frame(minWidth: 70)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isSelected ? Color("W2") : Color("G4"))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !isExpanded {
                Rectangle()
                    .fill(Color("G4").opacity(0.35))
                    .frame(height: 1)
                    .padding(.top, 1)
            }
        }
        .padding(.bottom, isExpanded ? 12 : 24)
    }
}

// MARK: - Календарь одного месяца

struct BookingCalendarMonth {
    let year: Int
    let month: Int
    let title: String
    let closedDays: Set<Int>
}

enum BookingCalendarMock {
    static let calendar: Calendar = {
        var c = Calendar.current
        c.locale = Locale(identifier: "ru_RU")
        c.firstWeekday = 2
        return c
    }()

    static let months: [BookingCalendarMonth] = [
        BookingCalendarMonth(
            year: 2025,
            month: 11,
            title: "Ноябрь",
            closedDays: [8, 16, 23, 30]
        ),
        BookingCalendarMonth(
            year: 2025,
            month: 12,
            title: "Декабрь",
            closedDays: [6, 13, 20, 27]
        )
    ]

    static func numberOfDays(in month: BookingCalendarMonth) -> Int {
        let comps = DateComponents(year: month.year, month: month.month)
        let date = calendar.date(from: comps)!
        return calendar.range(of: .day, in: .month, for: date)!.count
    }

    static func firstWeekdayOffset(in month: BookingCalendarMonth) -> Int {
        let comps = DateComponents(year: month.year, month: month.month, day: 1)
        let date = calendar.date(from: comps)!
        let weekday = calendar.component(.weekday, from: date)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        return offset
    }
}

// MARK: - Сетка календаря

struct CalendarMonthView: View {
    let month: BookingCalendarMonth
    @Binding var selectedDate: Date?

    private let calendar = BookingCalendarMock.calendar

    private var daysCount: Int {
        BookingCalendarMock.numberOfDays(in: month)
    }

    private var firstDayOffset: Int {
        BookingCalendarMock.firstWeekdayOffset(in: month)
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 7)
        let weekdaySymbols = weekdayShortSymbols()

        LazyVGrid(columns: columns, spacing: 6) {
            // Дни недели
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .typography(AppFont.roll1)
                    .foregroundColor(Color("G3"))
                    .frame(maxWidth: .infinity)
            }

            // Пустые ячейки до первого числа
            ForEach(0..<firstDayOffset, id: \.self) { _ in
                Color.clear
                    .frame(height: 32)
            }

            // Дни месяца
            ForEach(1...daysCount, id: \.self) { day in
                dayCell(day: day)
            }
        }
        .padding(.top, 4)
    }

    private func weekdayShortSymbols() -> [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let fromMonday = Array(symbols[1...]) + [symbols[0]]
        return fromMonday.map { String($0.prefix(2)) }
    }

    private func dayCell(day: Int) -> some View {
        let components = DateComponents(year: month.year, month: month.month, day: day)
        guard let date = calendar.date(from: components) else {
            return AnyView(EmptyView())
        }

        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let isClosed = month.closedDays.contains(day)

        let textColor: Color
        let bgColor: Color?

        if isClosed {
            bgColor = Color("R1")
            textColor = .white
        } else if isSelected {
            bgColor = Color("W2")
            textColor = Color("B4")
        } else {
            bgColor = nil
            textColor = Color("W2")
        }

        return AnyView(
            Button {
                guard !isClosed else { return }
                selectedDate = isSelected ? nil : date
            } label: {
                ZStack {
                    if let bgColor {
                        Circle()
                            .fill(bgColor)
                    }

                    Text("\(day)")
                        .typography(AppFont.roll1)
                        .foregroundColor(textColor)
                }
                .frame(height: 32)
            }
            .buttonStyle(.plain)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BookingTimeView(source: .fromMaster)
            .environmentObject(BookingFlowState())
            .preferredColorScheme(.dark)
    }
}
