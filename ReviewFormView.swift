import SwiftUI
import PhotosUI

struct ReviewFormView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState
    @Environment(\.dismiss) private var dismiss

    let booking: Booking

    // текст отзыва
    @State private var text: String = ""

    // фото
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showImagePicker = false

    // алерт «отправлено»
    @State private var showSuccessAlert = false

    // можно ли публиковать
    private var canPublish: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && imageData != nil
    }

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // поле текста
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ваш отзыв")
                                .typography(AppFont.lead3)
                                .foregroundColor(Color("W2"))

                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $text)
                                    .font(AppFont.text.font)
                                    .foregroundColor(Color("W2"))
                                    .padding(12)
                                    .frame(minHeight: 140)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color("B1"))
                                    )

                                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Расскажите, что вам понравилось…")
                                        .typography(AppFont.subtitle)
                                        .foregroundColor(Color("G3"))
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 18)
                                }
                            }
                        }

                        // блок добавления фото
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Фото")
                                .typography(AppFont.lead3)
                                .foregroundColor(Color("W2"))

                            HStack(spacing: 12) {
                                PhotosPicker(
                                    selection: $selectedPhoto,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    HStack {
                                        Image(systemName: "photo.on.rectangle")
                                            .font(.system(size: 18, weight: .medium))

                                        Text(imageData == nil ? "Добавить фото" : "Изменить фото")
                                            .typography(AppFont.roll1)
                                    }
                                    .foregroundColor(Color("B4"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color("W2"))
                                    )
                                }
                            }

                            if let data = imageData,
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal, 21)
                    .padding(.top, 8)
                }

                // кнопка «Опубликовать»
                Button {
                    publish()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(canPublish ? Color("W2") : Color("G4"))

                        Text("Опубликовать")
                            .typography(AppFont.lead2)
                            .foregroundColor(canPublish ? Color("B4") : Color("W2"))
                    }
                    .frame(height: 64)
                    .padding(.horizontal, 21)
                    .padding(.bottom, 24)
                }
                .disabled(!canPublish)
            }
        }
        // новый синтаксис onChange для iOS 17+
        .onChange(of: selectedPhoto) { oldValue, newValue in
            guard let newItem = newValue else {
                imageData = nil
                return
            }

            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        imageData = data
                    }
                }
            }
        }
        .alert("Спасибо за отзыв!", isPresented: $showSuccessAlert) {
            Button("Ок") {
                dismiss()
            }
        } message: {
            Text("Ваш отзыв будет опубликован после проверки.")
        }
        .navigationBarBackButtonHidden(true)
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

            Text("Оставить отзыв")
                .typography(AppFont.lead1)
                .foregroundColor(Color("W2"))

            Spacer()
        }
        .padding(.horizontal, 21)
        .padding(.top, 24)
    }

    // MARK: - Publish

    private func publish() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        bookingFlow.addReview(
            for: booking,
            text: trimmed,
            imageData: imageData
        )

        showSuccessAlert = true
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReviewFormView(
            booking: Booking(
                serviceTitle: "Полная мойка кузова",
                masterName: "Иван Петров",
                date: Date(),
                time: "10:30",
                carPlate: "О212УС31",
                createdAt: Date()
            )
        )
        .environmentObject(BookingFlowState())
    }
    .preferredColorScheme(.dark)
}
