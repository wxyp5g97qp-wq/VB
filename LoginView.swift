import SwiftUI

struct LoginView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState

    @State private var phoneDigits: String = ""      // только цифры
    @State private var isCalling: Bool = false

    // Валидность номера: 10 цифр после +7
    private var isPhoneValid: Bool {
        phoneDigits.count == 10
    }

    var body: some View {
        ZStack {
            // Фон
            Color("BackgroundPrimary")
                .ignoresSafeArea()
                .onTapGesture { hideKeyboard() }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {

                    // Заголовок
                    Text("Введите ваш номер")
                        .typography(AppFont.lead1)
                        .foregroundColor(Color("W2"))
                        .padding(.top, 60)

                    // Поле + кнопка (кнопка СРАЗУ под полем)
                    VStack(alignment: .center, spacing: 24) {
                        PhoneTextField(phoneDigits: $phoneDigits)

                        PrimaryButton(
                            title: "Авторизация",
                            enabled: isPhoneValid
                        ) {
                            startCallFlow()
                        }
                    }

                    // Текст условий внизу блока
                    Text("Продолжая вы соглашаетесь с нашими Условиями обслуживания и Политикой конфиденциальности")
                        .typography(AppFont.text)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color("W2"))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }

            // Оверлей "идёт звонок"
            if isCalling {
                CallOverlayView()
            }
        }
    }

    // MARK: - Логика "звонка" и авторизации

    private func startCallFlow() {
        hideKeyboard()
        isCalling = true

        // Заглушка: имитация звонка 2 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCalling = false

            // Сохраняем номер и помечаем, что пользователь авторизован
            bookingFlow.userPhone = "+7" + phoneDigits
            bookingFlow.isLoggedIn = true
            // Дальше RootView сам покажет ProfileFormView,
            // т.к. isLoggedIn == true, а isProfileCompleted == false
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(BookingFlowState())
    }
    .preferredColorScheme(.dark)
}

//
// MARK: - Поле телефона
//

struct PhoneTextField: View {
    @Binding var phoneDigits: String   // здесь храним ТОЛЬКО цифры

    // форматированная строка для отображения
    private var formattedPhone: String {
        formatFromDigits(phoneDigits)
    }

    var body: some View {
        ZStack {
            // ФОН ПОЛЯ
            RoundedRectangle(cornerRadius: 10)
                .fill(Color("W2"))

            // ПЛЕЙСХОЛДЕР
            if phoneDigits.isEmpty {
                Text("+7(999)999-99-99")
                    .font(AppFont.lead2.font)          // 28 / Bold
                    .foregroundColor(Color("G3"))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
            }

            // ВВОД
            TextField(
                "",
                text: Binding(
                    get: { formattedPhone },
                    set: { newValue in
                        phoneDigits = normalizeDigits(newValue)
                    }
                )
            )
            .keyboardType(.numberPad)
            .textContentType(.telephoneNumber)
            .disableAutocorrection(true)
            .font(AppFont.lead2.font)
            .foregroundColor(Color("B4"))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .padding(.horizontal, 24)
        }
        .frame(height: 65)
    }
}

//
// MARK: - Кнопка
//

struct PrimaryButton: View {
    let title: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            if enabled { action() }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(enabled
                          ? Color("W2")            // активная
                          : Color("G4"))          // неактивная

                Text(title)
                    .typography(AppFont.lead2)    // 28 / Bold
                    .foregroundColor(
                        enabled
                        ? Color("B4")            // текст на активной
                        : Color("W2")            // текст на неактивной
                    )
                    .lineLimit(1)
            }
            .frame(height: 72)
        }
        .disabled(!enabled)
    }
}

//
// MARK: - Оверлей "идёт звонок"
//

struct CallOverlayView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Идёт звонок для авторизации")
                    .typography(AppFont.lead2)
                    .foregroundColor(Color("W2"))

                Text("Номер: +7 ••• •••–••–••")
                    .typography(AppFont.lead2)
                    .foregroundColor(Color("G3"))
                    .multilineTextAlignment(.center)

                ProgressView()
                    .tint(Color("W2"))
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("BackgroundPrimary"))
            )
            .padding(40)
        }
    }
}

// MARK: - Хелперы для телефона

private func digitsOnly(_ value: String) -> String {
    value.filter { "0123456789".contains($0) }
}

private func normalizeDigits(_ value: String) -> String {
    var d = digitsOnly(value)

    if d.hasPrefix("8") { d.removeFirst() }
    if d.hasPrefix("7") { d.removeFirst() }

    if d.count > 10 {
        d = String(d.prefix(10))
    }
    return d
}

private func formatFromDigits(_ digits: String) -> String {
    if digits.isEmpty {
        return ""
    }

    var result = "+7"
    let count = digits.count
    let d = digits

    if count > 0 {
        result += "(" + String(d.prefix(3))
    }
    if count >= 3 {
        let start = d.index(d.startIndex, offsetBy: 3)
        let tail = String(d[start...])
        result += ")" + String(tail.prefix(3))
    }
    if count >= 6 {
        let start = d.index(d.startIndex, offsetBy: 6)
        let tail = String(d[start...])
        result += "-" + String(tail.prefix(2))
    }
    if count >= 8 {
        let start = d.index(d.startIndex, offsetBy: 8)
        let tail = String(d[start...])
        result += "-" + String(tail.prefix(2))
    }

    return result
}

//
// MARK: - Скрытие клавиатуры
//

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
#endif
