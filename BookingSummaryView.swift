import SwiftUI

struct BookingSummaryView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState
    @Environment(\.dismiss) private var dismiss

    /// Вызывается после успешного создания записи и нажатия "Ок" в алерте.
    /// - для пользователя: переключаем таб на "Мои записи"
    /// - для админа: закрываем sheet "Добавить запись" и остаёмся на экране AdminBookingsView
    let onSuccess: (() -> Void)?

    init(onSuccess: (() -> Void)? = nil) {
        self.onSuccess = onSuccess
    }

    @State private var showSuccessAlert: Bool = false
    @State private var clientPhone: String = ""

    // форма заполнена полностью?
    private var isFormComplete: Bool {
        switch bookingFlow.userRole {
        case .user:
            return bookingFlow.selectedServiceTitle != nil &&
                   bookingFlow.selectedMasterName != nil &&
                   bookingFlow.selectedDate != nil &&
                   bookingFlow.selectedTime != nil &&
                   bookingFlow.selectedCar != nil

        case .admin:
            return bookingFlow.selectedServiceTitle != nil &&
                   bookingFlow.selectedMasterName != nil &&
                   bookingFlow.selectedDate != nil &&
                   bookingFlow.selectedTime != nil &&
                   !clientPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "dd MMMM yyyy"
        return f
    }()

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                header

                ScrollView {
                    VStack(spacing: 18) {

                        // УСЛУГА
                        NavigationLink {
                            ServicesView()
                        } label: {
                            editableRow(
                                title: "Услуга",
                                value: bookingFlow.selectedServiceTitle,
                                buttonTitle: bookingFlow.selectedServiceTitle == nil ? "Выбрать" : "Изменить"
                            )
                        }
                        .buttonStyle(.plain)

                        // МАСТЕР
                        NavigationLink {
                            // просто переходим на выбор мастера;
                            // дальнейший флоу решает MasterSelectionView + BookingTimeView
                            MasterSelectionView()
                        } label: {
                            editableRow(
                                title: "Мастер",
                                value: bookingFlow.selectedMasterName,
                                buttonTitle: bookingFlow.selectedMasterName == nil ? "Выбрать" : "Изменить"
                            )
                        }
                        .buttonStyle(.plain)

                        // ДАТА И ВРЕМЯ
                        NavigationLink {
                            // источник для BookingTimeView зависит от роли
                            let timeSource: BookingTimeSource = {
                                switch bookingFlow.userRole {
                                case .user:  return .userFromSummary
                                case .admin: return .adminFromSummary
                                }
                            }()

                            BookingTimeView(source: timeSource)
                        } label: {
                            let dateText: String? = {
                                if let date = bookingFlow.selectedDate,
                                   let time = bookingFlow.selectedTime {
                                    let d = BookingSummaryView.dateFormatter.string(from: date)
                                    return "\(d), \(time)"
                                } else {
                                    return nil
                                }
                            }()

                            editableRow(
                                title: "Дата и время",
                                value: dateText,
                                buttonTitle: dateText == nil ? "Выбрать" : "Изменить"
                            )
                        }
                        .buttonStyle(.plain)

                        // АВТО — только для обычного пользователя
                        if bookingFlow.userRole == .user {
                            NavigationLink {
                                SelectCarView()
                            } label: {
                                editableRow(
                                    title: "Авто",
                                    value: bookingFlow.selectedCar?.number,
                                    buttonTitle: bookingFlow.selectedCar == nil ? "Выбрать" : "Изменить"
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Телефон клиента — только для админа
                        if bookingFlow.userRole == .admin {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Телефон клиента")
                                    .typography(AppFont.text)
                                    .foregroundColor(Color("G3"))

                                TextField("Номер телефона", text: $clientPhone)
                                    .keyboardType(.phonePad)
                                    .font(AppFont.roll1.font)
                                    .foregroundColor(Color("B4"))
                                    .padding(.horizontal, 14)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color("W2"))
                                    )
                            }
                            .padding(.horizontal, 21)
                        }
                    }
                    .padding(.horizontal, 21)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }

                // Кнопка "Записаться"
                Button {
                    handleConfirm()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isFormComplete ? Color("W2") : Color("G4"))

                        Text("Записаться")
                            .typography(AppFont.lead2)
                            .foregroundColor(isFormComplete ? Color("B4") : Color("W2"))
                    }
                    .frame(height: 64)
                    .padding(.horizontal, 21)
                    .padding(.bottom, 40)
                }
                .disabled(!isFormComplete)
            }
        }
        .alert(
            bookingFlow.userRole == .admin ? "Запись создана" : "Заявка отправлена",
            isPresented: $showSuccessAlert
        ) {
            Button("Ок") {
                if let onSuccess {
                    onSuccess()
                } else {
                    dismiss()
                }
            }
        } message: {
            if bookingFlow.userRole == .admin {
                Text("Клиент добавлен в список записей.")
            } else {
                Text("Мы свяжемся с вами для подтверждения записи.")
            }
        }
        .navigationBarBackButtonHidden(true)
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

            Text("Проверьте данные")
                .typography(AppFont.lead1)
                .foregroundColor(Color("W2"))

            Spacer()
        }
        .padding(.horizontal, 21)
        .padding(.top, 24)
    }

    // MARK: - Одна строка с кнопкой "Выбрать / Изменить"

    private func editableRow(
        title: String,
        value: String?,
        buttonTitle: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .typography(AppFont.text)
                    .foregroundColor(Color("G3"))

                Text(value ?? "Не выбрано")
                    .typography(AppFont.roll1)
                    .foregroundColor(Color("W2"))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(buttonTitle)
                .typography(AppFont.roll1)
                .foregroundColor(Color("W2"))
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("B3"))
                )
                .fixedSize()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("B1"))
        )
    }

    // MARK: - Обработка нажатия "Записаться"

    private func handleConfirm() {
        switch bookingFlow.userRole {
        case .user:
            bookingFlow.confirmCurrentBooking()
            showSuccessAlert = true

        case .admin:
            guard
                let service = bookingFlow.selectedService,
                let master = bookingFlow.selectedMaster,
                let date = bookingFlow.selectedDate,
                let time = bookingFlow.selectedTime
            else { return }

            let trimmedPhone = clientPhone
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmedPhone.isEmpty else { return }

            bookingFlow.createBookingAsAdmin(
                serviceTitle: "\(service.title) \(service.area)",
                masterName: master.name,
                date: date,
                time: time,
                clientPhone: trimmedPhone,
                price: nil
            )

            showSuccessAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        BookingSummaryView()
            .environmentObject(BookingFlowState())
            .preferredColorScheme(.dark)
    }
}
