import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState

    // режим редактирования
    @State private var isEditing = false

    // драфты полей профиля
    @State private var firstNameDraft: String = ""
    @State private var lastNameDraft: String = ""
    @State private var emailDraft: String = ""

    // аватар в режиме редактирования
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarDraftData: Data?

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    header

                    avatarAndEdit

                    userFields

                    if isEditing {
                        editButtons
                    } else {
                        garageButton
                        logoutButton
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let item = newValue else {
                avatarDraftData = nil
                return
            }

            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        avatarDraftData = data
                    }
                }
            }
        }
    }

    // MARK: - Заголовок

    private var header: some View {
        Text("Профиль")
            .typography(AppFont.lead1)
            .foregroundColor(Color("W2"))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Аватар + кнопка "Редактировать"

    private var avatarAndEdit: some View {
        HStack(alignment: .center) {

            avatarView

            Spacer()

            if !isEditing {
                Button {
                    startEditing()
                } label: {
                    Text("Редактировать")
                        .typography(AppFont.text)
                        .foregroundColor(Color("W2"))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("B3"))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Круглый аватар — в режиме редактирования можно менять через PhotosPicker
    private var avatarView: some View {
        let currentData: Data? = isEditing ? (avatarDraftData ?? bookingFlow.avatarImageData)
                                           : bookingFlow.avatarImageData

        let avatarContent: some View = Group {
            if let data = currentData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color("W2"))
                    .frame(width: 96, height: 96)
                    .overlay(
                        Text(String((bookingFlow.firstName.first ?? " ").uppercased()))
                            .typography(AppFont.lead1)
                            .foregroundColor(Color("B4"))
                    )
            }
        }

        return Group {
            if isEditing {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    avatarContent
                        .overlay(
                            Circle()
                                .stroke(Color("B3"), lineWidth: 2)
                        )
                }
            } else {
                avatarContent
            }
        }
    }

    // MARK: - Поля пользователя

    private var userFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isEditing {
                editableField(title: "Имя", text: $firstNameDraft)
                editableField(title: "Фамилия", text: $lastNameDraft)
                editableField(title: "Адрес электронной почты", text: $emailDraft)
            } else {
                readonlyField(title: "Имя", value: bookingFlow.firstName)
                readonlyField(title: "Фамилия", value: bookingFlow.lastName)
                readonlyField(title: "Номер телефона", value: bookingFlow.userPhone)
                readonlyField(title: "Адрес электронной почты", value: bookingFlow.email)
            }
        }
        .padding(.top, 10)
    }

    private func readonlyField(title: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .typography(AppFont.roll1)
                .foregroundColor(Color("W2"))

            TextField(
                "",
                text: .constant(display(value, placeholder: ""))
            )
            .disabled(true)
            .padding()
            .frame(height: 48)
            .background(Color("W2"))
            .cornerRadius(12)
            .foregroundColor(Color("B4"))
        }
    }

    private func editableField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .typography(AppFont.roll1)
                .foregroundColor(Color("W2"))

            TextField("", text: text)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.words)
                .padding()
                .frame(height: 48)
                .background(Color("W2"))
                .cornerRadius(12)
                .foregroundColor(Color("B4"))
        }
    }

    // MARK: - Кнопки в режиме просмотра

    private var garageButton: some View {
        NavigationLink {
            GarageView()
        } label: {
            Text("Гараж")
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
        .padding(.top, 10)
    }

    private var logoutButton: some View {
        Button {
            print("Logout tapped")
        } label: {
            Text("Выйти из профиля")
                .typography(AppFont.roll1)
                .foregroundColor(Color("W2"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("B3"))
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }

    // MARK: - Кнопки в режиме редактирования

    private var editButtons: some View {
        HStack(spacing: 12) {
            Button {
                cancelEditing()
            } label: {
                Text("Отменить")
                    .typography(AppFont.roll1)
                    .foregroundColor(Color("W2"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("B3"))
                    )
            }
            .buttonStyle(.plain)

            Button {
                saveEditing()
            } label: {
                Text("Сохранить")
                    .typography(AppFont.roll1)
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
        .padding(.top, 10)
    }

    // MARK: - Логика редактирования

    private func startEditing() {
        firstNameDraft = bookingFlow.firstName
        lastNameDraft  = bookingFlow.lastName
        emailDraft     = bookingFlow.email
        avatarDraftData = bookingFlow.avatarImageData
        selectedPhoto = nil

        withAnimation {
            isEditing = true
        }
    }

    private func cancelEditing() {
        // откатываем драфты
        firstNameDraft = bookingFlow.firstName
        lastNameDraft  = bookingFlow.lastName
        emailDraft     = bookingFlow.email
        avatarDraftData = nil
        selectedPhoto = nil

        withAnimation {
            isEditing = false
        }
    }

    private func saveEditing() {
        let trimmedFirst = firstNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast  = lastNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = emailDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        bookingFlow.updateProfile(
            firstName: trimmedFirst,
            lastName: trimmedLast,
            email: trimmedEmail,
            avatarData: avatarDraftData ?? bookingFlow.avatarImageData
        )

        withAnimation {
            isEditing = false
        }
    }

    // MARK: - Хелпер

    private func display(_ value: String?, placeholder: String) -> String {
        guard let value = value else { return placeholder }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? placeholder : trimmed
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(BookingFlowState())
    }
    .preferredColorScheme(.dark)
}
