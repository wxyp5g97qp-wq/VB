import SwiftUI
import UIKit
import PhotosUI

// MARK: - Верхние табы админ-панели постов

enum AdminPostsTab: String, CaseIterable {
    case news    = "Новости"
    case reviews = "Отзывы"
    case promos  = "Акции"
}

// MARK: - Основной экран "Посты" для админа

struct AdminPostsView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState

    @State private var selectedTab: AdminPostsTab = .news

    @State private var showNewsForm: Bool = false
    @State private var showPromoForm: Bool = false

    /// true – показываем отзывы на модерации, false – опубликованные
    @State private var showPendingReviews: Bool = false

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(spacing: 16) {

                // Заголовок
                Text("Посты")
                    .typography(AppFont.lead1)
                    .foregroundColor(Color("W2"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                    .padding(.horizontal, 21)

                // Верхний таббар
                AdminPostsTopTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 21)

                // Контент вкладки
                Group {
                    switch selectedTab {
                    case .news:
                        newsTab
                    case .reviews:
                        reviewsTab
                    case .promos:
                        promosTab
                    }
                }

                Spacer(minLength: 0)
            }
        }
        // sheet для создания новости
        .sheet(isPresented: $showNewsForm) {
            AdminPostFormView(title: "Новая новость") { text, imagesData in
                bookingFlow.addNewsPost(text: text, imagesData: imagesData)
            }
        }
        // sheet для создания акции
        .sheet(isPresented: $showPromoForm) {
            AdminPostFormView(title: "Новая акция") { text, imagesData in
                bookingFlow.addPromoPost(text: text, imagesData: imagesData)
            }
        }
    }

    // MARK: - Вкладка "Новости"

    private var newsTab: some View {
        VStack(spacing: 16) {

            // Верхний блок с кнопкой / заглушкой – с отступами
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    showNewsForm = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("Добавить новость")
                            .typography(AppFont.roll1)
                    }
                    .foregroundColor(Color("B4"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("W2"))
                    )
                }
                .buttonStyle(.plain)

                if bookingFlow.newsPosts.isEmpty {
                    Text("Пока нет новостей. Добавьте первую.")
                        .typography(AppFont.text)
                        .foregroundColor(Color("G3"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 21)

            // Лента постов – БЕЗ горизонтальных отступов, как у пользователя
            if !bookingFlow.newsPosts.isEmpty {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(bookingFlow.newsPosts) { post in
                            PostCardView(post: post)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        bookingFlow.deleteNewsPost(post)
                                    } label: {
                                        Text("Удалить")
                                    }
                                }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    // MARK: - Вкладка "Отзывы"

    private var reviewsTab: some View {
        VStack(spacing: 12) {

            // Заголовок + кнопка фильтра
            HStack {
                Text(showPendingReviews ? "Отзывы на модерации" : "Опубликованные отзывы")
                    .typography(AppFont.roll1)
                    .foregroundColor(Color("W2"))

                Spacer()

                Button {
                    withAnimation {
                        showPendingReviews.toggle()
                    }
                } label: {
                    Text(showPendingReviews ? "Показать опубликованные" : "Показать на модерации")
                        .typography(AppFont.icon)
                        .foregroundColor(Color("W2"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("B1"))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
            .padding(.horizontal, 21)

            // Список
            if showPendingReviews {
                // ждут подтверждения
                if bookingFlow.userReviews.isEmpty {
                    Text("Отзывов на модерации пока нет.")
                        .typography(AppFont.text)
                        .foregroundColor(Color("G3"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 21)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(bookingFlow.userReviews) { review in
                                AdminReviewCard(
                                    review: review,
                                    onApprove: {
                                        bookingFlow.approveReview(review)
                                    },
                                    onDelete: {
                                        bookingFlow.deleteReview(review)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 21)
                        .padding(.bottom, 24)
                    }
                }
            } else {
                // уже опубликованные (approvedReviews)
                if bookingFlow.approvedReviews.isEmpty {
                    Text("Опубликованных отзывов пока нет.")
                        .typography(AppFont.text)
                        .foregroundColor(Color("G3"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 21)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(bookingFlow.approvedReviews) { review in
                                AdminReviewCard(
                                    review: review,
                                    onApprove: nil,
                                    onDelete: nil
                                )
                            }
                        }
                        .padding(.horizontal, 21)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
    }

    // MARK: - Вкладка "Акции"

    private var promosTab: some View {
        VStack(spacing: 16) {

            // Верхний блок с кнопкой / заглушкой – с отступами
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    showPromoForm = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("Добавить акцию")
                            .typography(AppFont.roll1)
                    }
                    .foregroundColor(Color("B4"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("W2"))
                    )
                }
                .buttonStyle(.plain)

                if bookingFlow.promoPosts.isEmpty {
                    Text("Пока нет акций. Добавьте первую.")
                        .typography(AppFont.text)
                        .foregroundColor(Color("G3"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 21)

            // Лента постов – БЕЗ горизонтальных отступов
            if !bookingFlow.promoPosts.isEmpty {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(bookingFlow.promoPosts) { post in
                            PostCardView(post: post)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        bookingFlow.deletePromoPost(post)
                                    } label: {
                                        Text("Удалить")
                                    }
                                }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

// MARK: - Верхний таббар "Новости / Отзывы / Акции"

struct AdminPostsTopTabBar: View {
    @Binding var selectedTab: AdminPostsTab

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 100)
                .fill(Color("B3"))
                .frame(height: 41)

            HStack(spacing: 0) {
                ForEach(AdminPostsTab.allCases, id: \.self) { tab in
                    let isSelected = (tab == selectedTab)
                    let textColor = isSelected ? Color("B4") : Color("W2")

                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .typography(AppFont.roll1)
                            .foregroundColor(textColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 33)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color("W2") : Color.clear)
                            )
                    }
                }
            }
            .padding(4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Карточка отзыва с кнопками "Подтвердить / Удалить"

struct AdminReviewCard: View {
    let review: UserReview
    let onApprove: (() -> Void)?
    let onDelete: (() -> Void)?

    // Формат даты "24 января 2025"
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "dd MMMM yyyy"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text(review.text)
                .typography(AppFont.text)
                .foregroundColor(Color("W2"))
                .frame(maxWidth: .infinity, alignment: .leading)

            if let data = review.imageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 4) {
                if review.carBrand != nil || review.carModel != nil {
                    Text("Авто: \((review.carBrand ?? "")) \(review.carModel ?? "")")
                        .typography(AppFont.subtitle)
                        .foregroundColor(Color("W2"))
                }

                Text(Self.dateFormatter.string(from: review.createdAt))
                    .typography(AppFont.icon)
                    .foregroundColor(Color("G3"))
            }

            if onApprove != nil || onDelete != nil {
                HStack(spacing: 12) {
                    if let onDelete {
                        Button {
                            onDelete()
                        } label: {
                            Text("Удалить")
                                .typography(AppFont.roll1)
                                .foregroundColor(Color("W2"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("B1"))
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    if let onApprove {
                        Button {
                            onApprove()
                        } label: {
                            Text("Подтвердить")
                                .typography(AppFont.roll1)
                                .foregroundColor(Color("B4"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("W2"))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("B1"))
        )
    }
}

// MARK: - Форма создания новости / акции (текст + несколько фото)

struct AdminPostFormView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let onSave: (String, [Data]) -> Void   // (text, imagesData)

    @State private var postText: String = ""

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var imagesData: [Data] = []

    private var canSave: Bool {
        !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !imagesData.isEmpty
    }

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Image("icon_back")
                            .renderingMode(.template)
                            .foregroundColor(Color("W2"))
                    }

                    Text(title)
                        .typography(AppFont.lead1)
                        .foregroundColor(Color("W2"))

                    Spacer()
                }
                .padding(.horizontal, 21)
                .padding(.top, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // Текст
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Текст")
                                .typography(AppFont.text)
                                .foregroundColor(Color("G3"))

                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $postText)
                                    .font(AppFont.text.font)
                                    .foregroundColor(Color("W2"))
                                    .padding(10)
                                    .frame(minHeight: 160)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color("B1"))
                                    )

                                if postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Опишите новость или акцию…")
                                        .typography(AppFont.subtitle)
                                        .foregroundColor(Color("G3"))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                }
                            }
                        }

                        // Фото
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Фото")
                                .typography(AppFont.text)
                                .foregroundColor(Color("G3"))

                            PhotosPicker(
                                selection: $selectedPhotos,
                                maxSelectionCount: 10,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 18, weight: .medium))
                                    Text(imagesData.isEmpty ? "Добавить фото" : "Изменить фото (\(imagesData.count))")
                                        .typography(AppFont.roll1)
                                }
                                .foregroundColor(Color("B4"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color("W2"))
                                )
                            }

                            if !imagesData.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(imagesData.enumerated()), id: \.offset) { index, data in
                                            if let uiImage = UIImage(data: data) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 120, height: 120)
                                                    .clipped()
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 21)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }

                Button {
                    onSave(postText, imagesData)
                    dismiss()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(canSave ? Color("W2") : Color("G4"))

                        Text("Опубликовать")
                            .typography(AppFont.lead2)
                            .foregroundColor(canSave ? Color("B4") : Color("W2"))
                    }
                    .frame(height: 60)
                    .padding(.horizontal, 21)
                    .padding(.bottom, 24)
                }
                .disabled(!canSave)
            }
        }
        .onChange(of: selectedPhotos) { _, newItems in
            Task {
                var loaded: [Data] = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        loaded.append(data)
                    }
                }
                await MainActor.run {
                    imagesData = loaded
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdminPostsView()
            .environmentObject(BookingFlowState())
    }
    .preferredColorScheme(.dark)
}
