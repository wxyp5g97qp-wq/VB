import SwiftUI

struct ProfileFormView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState

    @State private var firstName: String = ""
    @State private var lastName: String = ""

    // Форма валидна, когда имя и фамилия не пустые
    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()
                .onTapGesture { hideKeyboard() }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // Заголовок
                    Text("Заполните данные о себе")
                        .typography(AppFont.lead1)
                        .foregroundColor(Color("W2"))
                        .padding(.top, 60)

                    // Поля
                    VStack(alignment: .leading, spacing: 16) {

                        Text("Имя")
                            .typography(AppFont.lead3)
                            .foregroundColor(Color("W2"))

                        ProfileTextField(text: $firstName)

                        Text("Фамилия")
                            .typography(AppFont.lead3)
                            .foregroundColor(Color("W2"))

                        ProfileTextField(text: $lastName)
                    }

                    // Кнопка сразу под полями
                    ProfilePrimaryButton(
                        title: "Далее",
                        enabled: isFormValid
                    ) {
                        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedLast  = lastName.trimmingCharacters(in: .whitespacesAndNewlines)

                        bookingFlow.firstName = trimmedFirst
                        bookingFlow.lastName = trimmedLast
                        bookingFlow.isProfileCompleted = true
                        // RootView после этого покажет MainTabView
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // если вдруг в стейте уже есть данные — подставим их
            if !bookingFlow.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                firstName = bookingFlow.firstName
            }
            if !bookingFlow.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lastName = bookingFlow.lastName
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileFormView()
            .environmentObject(BookingFlowState())
    }
    .preferredColorScheme(.dark)
}

//
// MARK: - Поле ввода
//

struct ProfileTextField: View {
    @Binding var text: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color("W2"))

            TextField("", text: $text)
                .font(AppFont.roll1.font)
                .foregroundColor(Color("B4"))
                .padding(.horizontal, 16)
        }
        .frame(height: 50)
    }
}

//
// MARK: - Кнопка Далее
//

struct ProfilePrimaryButton: View {
    let title: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            if enabled { action() }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(enabled ? Color("W2") : Color("G4"))

                Text(title)
                    .typography(AppFont.lead2)
                    .foregroundColor(enabled ? Color("B4") : Color("W2"))
            }
            .frame(height: 72)
        }
        .disabled(!enabled)
    }
}
