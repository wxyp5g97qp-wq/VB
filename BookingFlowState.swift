import Foundation
import Combine

// MARK: - Модели

/// Статус записи клиента
enum BookingStatus: String, Codable {
    case active      // актуальная
    case cancelled   // отменена пользователем / админом
    case completed   // выполнена (на будущее)
}

/// Роль текущего пользователя (клиент / админ)
enum UserRole: String, Codable {
    case user
    case admin
}

/// Одна машина
struct CarItem: Identifiable, Equatable, Codable {
    let id: UUID
    var number: String
    var brand: String?
    var model: String?
    var year: Int?
    var bodyType: String?

    init(
        id: UUID = UUID(),
        number: String,
        brand: String? = nil,
        model: String? = nil,
        year: Int? = nil,
        bodyType: String? = nil
    ) {
        self.id = id
        self.number = number
        self.brand = brand
        self.model = model
        self.year = year
        self.bodyType = bodyType
    }
}

/// Одна запись клиента
struct Booking: Identifiable, Codable {
    let id: UUID

    let serviceTitle: String
    let masterName: String
    let date: Date
    let time: String
    let carPlate: String
    let createdAt: Date
    var status: BookingStatus

    /// Предварительно согласованная сумма (может быть nil)
    var price: Int?

    /// Телефон клиента, на которого оформлена запись
    var clientPhone: String?

    init(
        id: UUID = UUID(),
        serviceTitle: String,
        masterName: String,
        date: Date,
        time: String,
        carPlate: String,
        createdAt: Date,
        status: BookingStatus = .active,
        price: Int? = nil,
        clientPhone: String? = nil
    ) {
        self.id = id
        self.serviceTitle = serviceTitle
        self.masterName = masterName
        self.date = date
        self.time = time
        self.carPlate = carPlate
        self.createdAt = createdAt
        self.status = status
        self.price = price
        self.clientPhone = clientPhone
    }
}

/// Отзыв пользователя (ожидающий модерации или уже подтверждённый)
struct UserReview: Identifiable {
    let id = UUID()
    let bookingId: UUID
    let text: String
    let createdAt: Date
    let carBrand: String?
    let carModel: String?
    /// Фото из галереи
    let imageData: Data?
}

// MARK: - Общее состояние

final class BookingFlowState: ObservableObject {

    // MARK: Авторизация / профиль

    @Published var isLoggedIn: Bool {
        didSet { UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn") }
    }

    @Published var isProfileCompleted: Bool {
        didSet { UserDefaults.standard.set(isProfileCompleted, forKey: "isProfileCompleted") }
    }

    @Published var userPhone: String {
        didSet { UserDefaults.standard.set(userPhone, forKey: "userPhone") }
    }

    @Published var firstName: String {
        didSet { UserDefaults.standard.set(firstName, forKey: "firstName") }
    }

    @Published var lastName: String {
        didSet { UserDefaults.standard.set(lastName, forKey: "lastName") }
    }

    // MARK: - Флаги сценариев

    /// true — когда админ создаёт запись через AdminBookingsView
    @Published var isAdminBookingFlow: Bool = false
    
    @Published var email: String {
        didSet { UserDefaults.standard.set(email, forKey: "email") }
    }

    /// Аватарка профиля (картинка в кружке)
    @Published var avatarImageData: Data? {
        didSet { UserDefaults.standard.set(avatarImageData, forKey: "avatarImageData") }
    }

    /// Роль текущего пользователя (user / admin)
    @Published var userRole: UserRole {
        didSet { UserDefaults.standard.set(userRole.rawValue, forKey: "userRole") }
    }

    // MARK: Гараж

    @Published var cars: [CarItem]
    
    /// Гаражи клиентов по телефону (только для записей, созданных админом)
    @Published var clientGarages: [String: [CarItem]]

    // MARK: Текущая запись (выбор в процессе — пользовательский flow)

    @Published var selectedService: ServiceItem?
    @Published var selectedMaster: Master?
    @Published var selectedDate: Date?
    @Published var selectedTime: String?
    @Published var selectedCar: CarItem?

    // MARK: Все записи

    @Published var bookings: [Booking]

    // MARK: Посты (для главной / админа)

    /// Новости / работы (вкладка "Работы"/"Новости")
    @Published var newsPosts: [Post]

    /// Акции (вкладка "Акции")
    @Published var promoPosts: [Post]

    // MARK: Отзывы пользователей

    /// Отзывы, которые оставили пользователи и ждут модерации
    @Published var userReviews: [UserReview]

    /// Подтверждённые отзывы (для вкладки "Отзывы" на главной)
    @Published var approvedReviews: [UserReview]

    // MARK: Выбранная вкладка таббара для клиента

    @Published var selectedTab: MainTab = .main

    // MARK: - Инициализация

    init() {
        let defaults = UserDefaults.standard

        self.isLoggedIn = defaults.bool(forKey: "isLoggedIn")
        self.isProfileCompleted = defaults.bool(forKey: "isProfileCompleted")
        self.userPhone = defaults.string(forKey: "userPhone") ?? ""
        self.firstName = defaults.string(forKey: "firstName") ?? ""
        self.lastName = defaults.string(forKey: "lastName") ?? ""
        self.email = defaults.string(forKey: "email") ?? ""
        self.avatarImageData = defaults.data(forKey: "avatarImageData")

        if
            let roleRaw = defaults.string(forKey: "userRole"),
            let savedRole = UserRole(rawValue: roleRaw)
        {
            self.userRole = savedRole
        } else {
            self.userRole = .user
        }

        // стартовый гараж (можно сделать пустым)
        self.cars = [
            CarItem(number: "О212УС31",
                    brand: "LADA",
                    model: "Vesta",
                    year: 2023,
                    bodyType: "Универсал")
        ]

        self.bookings = []
        self.clientGarages = [:]

        // стартовые посты (как у пользователя)
        self.newsPosts = SampleData.worksPosts
        self.promoPosts = SampleData.promoPosts

        // отзывы — по умолчанию пустые
        self.userReviews = []
        self.approvedReviews = []
    }

    // MARK: Удобные геттеры

    var selectedServiceTitle: String? {
        guard let service = selectedService else { return nil }
        return "\(service.title) \(service.area)"
    }

    var selectedMasterName: String? {
        selectedMaster?.name
    }

    var selectedCarPlate: String? {
        selectedCar?.number
    }

    // MARK: Обновление профиля

    func updateProfile(
        firstName: String,
        lastName: String,
        email: String,
        avatarData: Data?
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.avatarImageData = avatarData
    }

    // MARK: Сброс текущей записи (user-flow)

    func resetService() {
        selectedService = nil
        resetMaster()
    }

    func resetMaster() {
        selectedMaster = nil
        resetDateTime()
    }

    func resetDateTime() {
        selectedDate = nil
        selectedTime = nil
    }
    
    func resetCar() {
        selectedCar = nil
    }

    func resetAll() {
        selectedService = nil
        selectedMaster = nil
        selectedDate = nil
        selectedTime = nil
        selectedCar = nil
    }

    // MARK: Работа с гаражом

    func addCar(
        number: String,
        brand: String? = nil,
        model: String? = nil,
        year: Int? = nil,
        bodyType: String? = nil
    ) {
        let trimmed = number.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let car = CarItem(
            number: trimmed,
            brand: brand,
            model: model,
            year: year,
            bodyType: bodyType
        )
        cars.append(car)
    }

    func updateCar(
        _ car: CarItem,
        newNumber: String,
        newBrand: String? = nil,
        newModel: String? = nil,
        newYear: Int? = nil,
        newBodyType: String? = nil
    ) {
        guard let index = cars.firstIndex(where: { $0.id == car.id }) else { return }

        cars[index].number = newNumber
        cars[index].brand = newBrand
        cars[index].model = newModel
        cars[index].year = newYear
        cars[index].bodyType = newBodyType

        if selectedCar?.id == car.id {
            selectedCar = cars[index]
        }
    }

    func deleteCar(_ car: CarItem) {
        cars.removeAll { $0.id == car.id }
        if selectedCar?.id == car.id {
            selectedCar = nil
        }
    }

    // MARK: Подтверждение записи (user-flow)

    func confirmCurrentBooking() {
        guard
            let service = selectedService,
            let master = selectedMaster,
            let date = selectedDate,
            let time = selectedTime,
            let car = selectedCar
        else {
            return
        }

        // для обычного пользователя price = nil,
        // clientPhone — его собственный номер
        let booking = Booking(
            serviceTitle: "\(service.title) \(service.area)",
            masterName: master.name,
            date: date,
            time: time,
            carPlate: car.number,
            createdAt: Date(),
            status: .active,
            price: nil,
            clientPhone: userPhone
        )

        bookings.insert(booking, at: 0)
        resetAll()
    }

    // MARK: Работа с постами (Новости / Акции) — для админа


    /// Новость: текст + несколько картинок
    func addNewsPost(text: String, imagesData: [Data]) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let dateString = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .long,
            timeStyle: .none
        )

        let companyName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let authorName = companyName.isEmpty ? "VBunker31" : companyName

        let post = Post(
            source: .admin,
            authorName: authorName,
            authorAvatarName: "user_admin",
            carName: "Новости студии",
            dateString: dateString,
            images: [],
            text: trimmedText,
            adminImagesData: imagesData,
            userImageData: nil
        )

        newsPosts.insert(post, at: 0)
    }

    /// Акция: текст + несколько картинок
    func addPromoPost(text: String, imagesData: [Data]) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let dateString = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .long,
            timeStyle: .none
        )

        let companyName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let authorName = companyName.isEmpty ? "VBunker31" : companyName

        let post = Post(
            source: .admin,
            authorName: authorName,
            authorAvatarName: "user_admin",
            carName: "Акция",
            dateString: dateString,
            images: [],
            text: trimmedText,
            adminImagesData: imagesData,
            userImageData: nil
        )

        promoPosts.insert(post, at: 0)
    }

    func deleteNewsPost(_ post: Post) {
        newsPosts.removeAll { $0.id == post.id }
    }

    func deletePromoPost(_ post: Post) {
        promoPosts.removeAll { $0.id == post.id }
    }

    // MARK: Работа с отзывами

    /// Пользователь оставил отзыв (из ReviewFormView)
    func addReview(for booking: Booking, text: String, imageData: Data?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let car = cars.first { $0.number == booking.carPlate }

        let review = UserReview(
            bookingId: booking.id,
            text: trimmed,
            createdAt: Date(),
            carBrand: car?.brand,
            carModel: car?.model,
            imageData: imageData
        )

        // кладём в "ожидающие модерации"
        userReviews.insert(review, at: 0)
    }

    /// Админ подтвердил отзыв — переносим из userReviews в approvedReviews
    func approveReview(_ review: UserReview) {
        guard let index = userReviews.firstIndex(where: { $0.id == review.id }) else { return }
        let approved = userReviews.remove(at: index)
        approvedReviews.insert(approved, at: 0)
    }

    /// Админ удалил отзыв (из ожидающих)
    func deleteReview(_ review: UserReview) {
        userReviews.removeAll { $0.id == review.id }
    }

    // MARK: Работа с ценой / созданием записи админом

    /// Изменение цены существующей записи (из AdminBookingsView)
    func updateBookingPrice(_ price: Int?, for booking: Booking) {
        guard let index = bookings.firstIndex(where: { $0.id == booking.id }) else { return }
        bookings[index].price = price
    }

    /// Полное создание записи админом (БЕЗ выбора авто)
    func createBookingAsAdmin(
        serviceTitle: String,
        masterName: String,
        date: Date,
        time: String,
        clientPhone: String,
        price: Int?
    ) {
        let trimmedPhone = clientPhone.trimmingCharacters(in: .whitespacesAndNewlines)

        let booking = Booking(
            serviceTitle: serviceTitle,
            masterName: masterName,
            date: date,
            time: time,
            carPlate: "Не указан",          // авто админ не выбирает
            createdAt: Date(),
            status: .active,
            price: price,
            clientPhone: trimmedPhone.isEmpty ? nil : trimmedPhone
        )

        bookings.insert(booking, at: 0)
    }

    // MARK: - Гараж клиентов (по телефону) — только для админских записей

    /// Вернуть список автомобилей для указанного телефона
    func carsForClient(phone: String) -> [CarItem] {
        clientGarages[phone] ?? []
    }

    /// Добавить новое авто клиенту по телефону.
    /// Возвращает созданный CarItem (или nil, если номер пустой).
    @discardableResult
    func addCarForClient(
        phone: String,
        number: String,
        brand: String? = nil,
        model: String? = nil,
        year: Int? = nil,
        bodyType: String? = nil
    ) -> CarItem? {
        let trimmed = number.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var list = clientGarages[phone] ?? []

        let car = CarItem(
            number: trimmed,
            brand: brand,
            model: model,
            year: year,
            bodyType: bodyType
        )

        list.append(car)
        clientGarages[phone] = list
        return car
    }

    /// Обновить уже существующее авто клиента (по id)
    func updateCarForClient(phone: String, car: CarItem) {
        guard var list = clientGarages[phone] else { return }
        if let idx = list.firstIndex(where: { $0.id == car.id }) {
            list[idx] = car
            clientGarages[phone] = list
        }
    }
    
    // MARK: Отмена записи

    func cancelBooking(_ booking: Booking) {
        guard let index = bookings.firstIndex(where: { $0.id == booking.id }) else { return }
        bookings[index].status = .cancelled
        
        
    }
    
    // MARK: - Работа с клиентами админа

    /// Проверка — существует ли клиент по номеру
    func isRegistered(phone: String) -> Bool {
        return phone == userPhone
    }

    /// Временное авто для незарегистрированного пользователя
    @Published var tempCarForUnregistered: CarItem? = nil

    /// Сохранение авто, которое админ создал для незарегистрированного клиента
    func saveTempCarForUnregistered(_ car: CarItem, for phone: String) {
        // Позже заменишь на реальную базу
        tempCarForUnregistered = car
    }

    /// Возвращает гараж клиента по номеру
    func carsFor(phone: String) -> [CarItem] {
        if phone == userPhone {
            return cars
        }
        if let tempCarForUnregistered {
            return [tempCarForUnregistered]
        }
        return []
    }
}
