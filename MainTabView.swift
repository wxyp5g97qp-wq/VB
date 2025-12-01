import SwiftUI
import UIKit   // для Image(uiImage:)

// MARK: - Нижний таббар (4 вкладки)

enum MainTab: Int {
    case main
    case services
    case records
    case profile
}

struct MainTabView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch bookingFlow.selectedTab {
                case .main:
                    HomeView()
                case .services:
                    ServicesView()
                case .records:
                    RecordsView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity,
                   maxHeight: .infinity,
                   alignment: .top)

            CustomTabBar(selectedTab: $bookingFlow.selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Кастомный нижний TabBar

struct CustomTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 0) {
            tabButton(tab: .main,     title: "Главная",  iconName: "tab_home")
            tabButton(tab: .services, title: "Услуги",   iconName: "tab_services")
            tabButton(tab: .records,  title: "Записи",   iconName: "tab_records")
            tabButton(tab: .profile,  title: "Профиль",  iconName: "tab_profile")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 18)
        .background(Color("B1"))
    }

    private func tabButton(tab: MainTab, title: String, iconName: String) -> some View {
        let isSelected = (tab == selectedTab)
        let color = isSelected ? Color("W2") : Color("G3")

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 8) {
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 28)
                    .foregroundColor(color)

                Text(title)
                    .typography(AppFont.text)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Верхние табы на Главной

enum HomeTopTab: String, CaseIterable {
    case works   = "Работы"
    case reviews = "Отзывы"
    case promos  = "Акции"
}

// кто создал пост
enum PostSource {
    case admin   // Работы и Акции
    case user    // Отзывы
}

// Модель поста
struct Post: Identifiable {
    let id = UUID()

    let source: PostSource
    let authorName: String
    let authorAvatarName: String? // имя картинки в Assets
    let carName: String
    let dateString: String

    /// Статические картинки из ассетов (старые работы/акции)
    let images: [String]

    let text: String

    /// Фотки, загруженные админом (новости / акции)
    let adminImagesData: [Data]

    /// Одна фотка из пользовательского отзыва
    let userImageData: Data?
}

// MARK: - Экран «Главная»

struct HomeView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState
    @State private var selectedTopTab: HomeTopTab = .works

    private static let reviewDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "dd MMMM yyyy"
        return f
    }()

    var body: some View {
        ZStack {
            Color("B3")
                .ignoresSafeArea()

            VStack(spacing: 5) {

                HomeTopTabBar(selectedTab: $selectedTopTab)
                    .padding(.top, 1)
                    .padding(.horizontal, 15)

                Group {
                    switch selectedTopTab {
                    case .works:
                        // работы / новости теперь из состояния
                        PostsListView(posts: bookingFlow.newsPosts)

                    case .reviews:
                        // сначала ПОДТВЕРЖДЁННЫЕ отзывы пользователей, затем статические
                        PostsListView(posts: userReviewPosts + SampleData.reviewPosts)

                    case .promos:
                        // акции из состояния
                        PostsListView(posts: bookingFlow.promoPosts)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    /// Посты, собранные из ПОДТВЕРЖДЁННЫХ отзывов
    private var userReviewPosts: [Post] {
        bookingFlow.approvedReviews.map { review in
            let fullName = [bookingFlow.firstName, bookingFlow.lastName]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            let author = fullName.isEmpty ? "Клиент VBunker31" : fullName

            let carTitle: String
            if let brand = review.carBrand, let model = review.carModel,
               !brand.isEmpty, !model.isEmpty {
                carTitle = "\(brand) \(model)"
            } else {
                carTitle = "Авто клиента"
            }

            let dateStr = HomeView.reviewDateFormatter.string(from: review.createdAt)

            return Post(
                source: .user,
                authorName: author,
                authorAvatarName: nil,
                carName: carTitle,
                dateString: dateStr,
                images: [],
                text: review.text,
                adminImagesData: [],
                userImageData: review.imageData
            )
        }
    }
}

// MARK: - Верхний таббар (Работы / Отзывы / Акции)

struct HomeTopTabBar: View {
    @Binding var selectedTab: HomeTopTab

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 100)
                .fill(Color("B3"))
                .frame(height: 41)

            HStack(spacing: 0) {
                ForEach(HomeTopTab.allCases, id: \.self) { tab in
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

// MARK: - Лента постов

struct PostsListView: View {
    let posts: [Post]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color("G4").opacity(0.12))
                    .frame(height: 2)

                ForEach(posts.indices, id: \.self) { index in
                    let post = posts[index]

                    PostCardView(post: post)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if index < posts.count - 1 {
                        Rectangle()
                            .fill(Color("G4").opacity(0.12))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Карточка поста

struct PostCardView: View {
    let post: Post

    private let headerColor = Color("B3")
    private let bodyColor   = Color("B3")

    var body: some View {
        VStack(spacing: 0) {

            // Шапка
            HStack(alignment: .center, spacing: 12) {
                if let avatar = post.authorAvatarName {
                    Image(avatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color("G3"))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(post.authorName.prefix(1)))
                                .typography(AppFont.roll1)
                                .foregroundColor(Color("BackgroundPrimary"))
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .typography(AppFont.roll1)
                        .foregroundColor(Color("W2"))

                    Text("Авто: \(post.carName)")
                        .typography(AppFont.subtitle)
                        .foregroundColor(Color("W2"))
                }

                Spacer()
            }
            .padding(12)
            .background(headerColor)

            Rectangle()
                .fill(Color("G3").opacity(0.25))
                .frame(height: 1)

            // Тело поста
            VStack(alignment: .leading, spacing: 12) {

                // --- БЛОК ФОТО ---

                if let data = post.userImageData,
                   let uiImage = UIImage(data: data) {
                    // Фото из пользовательского отзыва
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(4.0 / 3.0, contentMode: .fit)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 0))

                } else if !post.adminImagesData.isEmpty {
                    // Несколько фоток, загруженных админом
                    if post.adminImagesData.count == 1,
                       let uiImage = UIImage(data: post.adminImagesData[0]) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(4.0 / 3.0, contentMode: .fit)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 0))
                    } else {
                        TabView {
                            ForEach(Array(post.adminImagesData.enumerated()), id: \.offset) { _, data in
                                if let img = UIImage(data: data) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .aspectRatio(4.0 / 3.0, contentMode: .fit)
                                        .clipped()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(4.0 / 3.0, contentMode: .fit)
                        .tabViewStyle(PageTabViewStyle())
                        .clipShape(RoundedRectangle(cornerRadius: 0))
                    }

                } else if !post.images.isEmpty {
                    // Статические картинки из ассетов
                    if post.images.count > 1 {
                        TabView {
                            ForEach(post.images, id: \.self) { imageName in
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(4.0 / 3.0, contentMode: .fit)
                                    .clipped()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(4.0 / 3.0, contentMode: .fit)
                        .tabViewStyle(PageTabViewStyle())
                        .clipShape(RoundedRectangle(cornerRadius: 0))
                    } else if let first = post.images.first {
                        Image(first)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(4.0 / 3.0, contentMode: .fit)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 0))
                    }
                }

                // Текст + дата
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.text)
                        .typography(AppFont.text)
                        .foregroundColor(Color("W2"))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Spacer()
                        Text(post.dateString)
                            .typography(AppFont.icon)
                            .foregroundColor(Color("G3"))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .background(bodyColor)
        }
        .cornerRadius(0)
    }
}

// MARK: - Примерные данные

enum SampleData {
    static let worksPosts: [Post] = [
        Post(
            source: .admin,
            authorName: "VBunker31",
            authorAvatarName: "user_admin",
            carName: "Changan Uni-S",
            dateString: "01 января 2025 года",
            images: ["image_1", "image_2", "image_3", "image_4"],
            text: """
            ❗️Установка амбиентой (контурной подсветки салона);
            ✅Оклеили малый комплекс зон риска полиуретановой пленкой: Капот, полоса крыши, фары, зона под ручками, внутренние пороги, зона погрузки;
            ⚫️Тонировка задней части 5% Llumar atr;
            """,
            adminImagesData: [],
            userImageData: nil
        ),
        Post(
            source: .admin,
            authorName: "VBunker31",
            authorAvatarName: "user_admin",
            carName: "BMW M5",
            dateString: "15 января 2025 года",
            images: ["work_3"],
            text: "Полная детейлинг-мойка и полировка кузова.",
            adminImagesData: [],
            userImageData: nil
        )
    ]

    static let reviewPosts: [Post] = [
        Post(
            source: .user,
            authorName: "Иван Иванов",
            authorAvatarName: "user_ivan",
            carName: "Audi A6",
            dateString: "20 января 2025 года",
            images: ["review_1"],
            text: "Остался очень доволен сервисом. Буду обращаться ещё!",
            adminImagesData: [],
            userImageData: nil
        ),
        Post(
            source: .user,
            authorName: "Павел Петров",
            authorAvatarName: "user_pavel",
            carName: "Toyota Camry",
            dateString: "22 января 2025 года",
            images: ["review_2"],
            text: "Сделали всё вовремя, отдельное спасибо за обслуживание.",
            adminImagesData: [],
            userImageData: nil
        )
    ]

    static let promoPosts: [Post] = [
        Post(
            source: .admin,
            authorName: "VBunker31",
            authorAvatarName: "user_admin",
            carName: "Jaguar",
            dateString: "До 31 января",
            images: ["promo_1"],
            text: "Скидка 20% на полную химчистку салона при записи в будни.",
            adminImagesData: [],
            userImageData: nil
        ),
        Post(
            source: .admin,
            authorName: "VBunker31",
            authorAvatarName: "user_admin",
            carName: "Любое авто",
            dateString: "Весь февраль",
            images: ["promo_2"],
            text: "Акция: третья мойка в подарок при покупке абонемента.",
            adminImagesData: [],
            userImageData: nil
        )
    ]
}

#Preview {
    NavigationStack {
        MainTabView()
            .environmentObject(BookingFlowState())
    }
    .preferredColorScheme(.dark)
}
