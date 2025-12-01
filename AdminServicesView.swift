import SwiftUI
import PhotosUI

// MARK: - Вкладки админ-экрана

enum AdminServicesTab: String, CaseIterable {
    case services = "Услуги"
    case masters  = "Мастера"
}

// MARK: - Модели только для админ-экрана

struct AdminService: Identifiable, Hashable {
    let id: UUID
    var category: String          // «Тонировка»
    var title: String             // «Передние стёкла»
    var durationMinutes: Int?     // время услуги (например, 60)
    var priceText: String         // «от 4400 ₽»
    var imageData: Data?          // картинка услуги

    init(
        id: UUID = UUID(),
        category: String,
        title: String,
        durationMinutes: Int? = nil,
        priceText: String,
        imageData: Data? = nil
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.durationMinutes = durationMinutes
        self.priceText = priceText
        self.imageData = imageData
    }
}

struct AdminMaster: Identifiable, Hashable {
    let id: UUID
    var name: String
    var categories: Set<String>   // список категорий услуг, с которыми работает мастер
    var imageData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        categories: Set<String> = [],
        imageData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.categories = categories
        self.imageData = imageData
    }
}

// MARK: - Основной экран «Услуги» для админа

struct AdminServicesView: View {
    @State private var selectedTab: AdminServicesTab = .services

    // Черновые данные только для этого экрана
    @State private var services: [AdminService] = [
        AdminService(category: "Тонировка",
                     title: "Передние стёкла",
                     durationMinutes: 60,
                     priceText: "от 4400 ₽"),
        AdminService(category: "Тонировка",
                     title: "Передние стёкла",
                     durationMinutes: 60,
                     priceText: "от 4400 ₽")
    ]

    @State private var masters: [AdminMaster] = [
        AdminMaster(name: "Дмитрий", categories: ["Тонировка", "Бронирование"]),
        AdminMaster(name: "Антон", categories: ["Полировка"]),
        AdminMaster(name: "Сергей", categories: ["Доп. услуги"])
    ]

    // Редактирование
    @State private var editingService: AdminService?
    @State private var editingMaster: AdminMaster?

    // Создание
    @State private var showCreateService = false
    @State private var showCreateMaster = false

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(spacing: 16) {

                // Заголовок
                Text("Наши услуги")
                    .typography(AppFont.lead1)
                    .foregroundColor(Color("W2"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                    .padding(.horizontal, 21)

                // Верхний таббар
                AdminServicesTopTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 21)

                Group {
                    switch selectedTab {
                    case .services:
                        servicesTab
                    case .masters:
                        mastersTab
                    }
                }

                Spacer(minLength: 0)
            }
        }
        // Редактирование существующей услуги
        .sheet(item: $editingService) { service in
            AdminServiceEditorView(
                allCategories: Array(allCategories).sorted(),
                initialService: service,
                onSave: { updated in
                    if let index = services.firstIndex(where: { $0.id == updated.id }) {
                        services[index] = updated
                    }
                },
                onDelete: {
                    services.removeAll { $0.id == service.id }
                }
            )
        }
        // Создание новой услуги
        .sheet(isPresented: $showCreateService) {
            AdminServiceEditorView(
                allCategories: Array(allCategories).sorted(),
                initialService: nil,
                onSave: { newService in
                    services.append(newService)
                },
                onDelete: nil
            )
        }
        // Редактирование существующего мастера
        .sheet(item: $editingMaster) { master in
            AdminMasterEditorView(
                allCategories: Array(allCategories).sorted(),
                initialMaster: master
            ) { updated in
                if let index = masters.firstIndex(where: { $0.id == updated.id }) {
                    masters[index] = updated
                }
            }
        }
        // Создание мастера
        .sheet(isPresented: $showCreateMaster) {
            AdminMasterEditorView(
                allCategories: Array(allCategories).sorted(),
                initialMaster: nil
            ) { newMaster in
                masters.append(newMaster)
            }
        }
    }

    /// Все категории, которые сейчас есть у услуг/мастеров
    private var allCategories: Set<String> {
        Set(services.map { $0.category }).union(
            masters.flatMap { $0.categories }
        )
    }

    // MARK: - Вкладка «Услуги»

    private var servicesTab: some View {
        VStack(spacing: 16) {

            // Кнопка «Добавить услугу»
            Button {
                showCreateService = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Добавить услугу")
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
            .padding(.horizontal, 21)

            // Список категорий с услугами
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(groupedServices.keys.sorted(), id: \.self) { category in
                        if let servicesInCategory = groupedServices[category] {
                            AdminServiceCategorySection(
                                category: category,
                                services: servicesInCategory,
                                onEdit: { service in
                                    editingService = service
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 0) // чтобы карточка была на всю ширину
                .padding(.bottom, 24)
            }
        }
    }

    /// Сгруппированные услуги по категории
    private var groupedServices: [String: [AdminService]] {
        Dictionary(grouping: services, by: { $0.category })
    }

    // MARK: - Вкладка «Мастера»

    private var mastersTab: some View {
        VStack(spacing: 16) {

            // Кнопка «Добавить мастера»
            Button {
                showCreateMaster = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Добавить мастера")
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
            .padding(.horizontal, 21)

            if masters.isEmpty {
                Text("Мастеров пока нет. Добавьте первого.")
                    .typography(AppFont.text)
                    .foregroundColor(Color("G3"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 21)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(masters) { master in
                            AdminMasterRow(
                                master: master,
                                onEdit: { editingMaster = master },
                                onDelete: {
                                    masters.removeAll { $0.id == master.id }
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
}

// MARK: - Верхний таббар «Услуги / Мастера»

struct AdminServicesTopTabBar: View {
    @Binding var selectedTab: AdminServicesTab

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 100)
                .fill(Color("B3"))
                .frame(height: 41)

            HStack(spacing: 0) {
                ForEach(AdminServicesTab.allCases, id: \.self) { tab in
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

// MARK: - Секция категории услуг

struct AdminServiceCategorySection: View {
    let category: String
    let services: [AdminService]
    let onEdit: (AdminService) -> Void

    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // заголовок категории
            HStack {
                Text(category)
                    .typography(AppFont.lead2)
                    .foregroundColor(Color("W2"))

                Spacer()

                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("W2"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color("B3"))

            if isExpanded {
                ForEach(services) { service in
                    AdminServiceRow(
                        service: service,
                        onEdit: { onEdit(service) }
                    )
                    .background(Color("B3"))
                }
            }
        }
    }
}

// MARK: - Одна услуга в списке (как у пользователя) + кнопка «Изменить»

struct AdminServiceRow: View {
    let service: AdminService
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Верхняя часть: большая «картинка» + кнопка «Изменить» справа
            HStack(alignment: .top, spacing: 12) {

                ZStack {
                    if let data = service.imageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        // плейсхолдер как у пользователя
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color("W2"))
                    }
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Button {
                    onEdit()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 18, weight: .medium))
                        Text("Изменить")
                            .typography(AppFont.icon)
                    }
                    .foregroundColor(Color("W2"))
                    .frame(width: 90, height: 90)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color("G3"))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Название + чип времени + цена
            VStack(alignment: .leading, spacing: 6) {
                Text(service.title)
                    .typography(AppFont.lead3)
                    .foregroundColor(Color("W2"))

                HStack(spacing: 10) {
                    if let duration = service.durationMinutes {
                        Text("\(duration) минут")
                            .typography(AppFont.icon)
                            .foregroundColor(Color("W2"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color("G3"))
                            )
                    }

                    Spacer()

                    Text(service.priceText)
                        .typography(AppFont.lead3)
                        .foregroundColor(Color("W2"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Одна строка мастера

struct AdminMasterRow: View {
    let master: AdminMaster
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let data = master.imageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color("G3"))
                    .frame(width: 48, height: 48)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(master.name)
                    .typography(AppFont.roll1)
                    .foregroundColor(Color("W2"))

                if !master.categories.isEmpty {
                    Text(master.categories.sorted().joined(separator: " • "))
                        .typography(AppFont.subtitle)
                        .foregroundColor(Color("G3"))
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .foregroundColor(Color("W2"))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("B1"))
        )
    }
}

// MARK: - Редактор услуги

struct AdminServiceEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let allCategories: [String]
    let initialService: AdminService?
    let onSave: (AdminService) -> Void
    let onDelete: (() -> Void)?

    @State private var category: String = ""
    @State private var useCustomCategory: Bool = false

    @State private var title: String = ""
    @State private var priceText: String = ""
    @State private var selectedDuration: Int? = nil

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?

    @State private var showDeleteAlert: Bool = false

    private let durationOptions = [30, 45, 60, 90, 120]

    init(
        allCategories: [String],
        initialService: AdminService?,
        onSave: @escaping (AdminService) -> Void,
        onDelete: (() -> Void)?
    ) {
        self.allCategories = allCategories
        self.initialService = initialService
        self.onSave = onSave
        self.onDelete = onDelete

        _category = State(initialValue: initialService?.category ?? "")
        _title = State(initialValue: initialService?.title ?? "")
        _priceText = State(initialValue: initialService?.priceText ?? "")
        _selectedDuration = State(initialValue: initialService?.durationMinutes)
        _imageData = State(initialValue: initialService?.imageData)
    }

    private var canSave: Bool {
        !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !priceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

                    Text(initialService == nil ? "Новая услуга" : "Редактор услуги")
                        .typography(AppFont.lead1)
                        .foregroundColor(Color("W2"))

                    Spacer()
                }
                .padding(.horizontal, 21)
                .padding(.top, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // Категория (выпадающий список + опция «Новая»)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Категория")
                                .typography(AppFont.text)
                                .foregroundColor(Color("G3"))

                            if !allCategories.isEmpty {
                                Menu {
                                    ForEach(allCategories, id: \.self) { cat in
                                        Button(cat) {
                                            category = cat
                                            useCustomCategory = false
                                        }
                                    }
                                    Button("Новая категория") {
                                        category = ""
                                        useCustomCategory = true
                                    }
                                } label: {
                                    HStack {
                                        Text(category.isEmpty ? "Выберите категорию" : category)
                                            .typography(AppFont.roll1)
                                            .foregroundColor(category.isEmpty ? Color("G3") : Color("B4"))

                                        Spacer()

                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color("G3"))
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color("W2"))
                                    )
                                }
                            }

                            if useCustomCategory || allCategories.isEmpty {
                                TextField("Введите новую категорию", text: $category)
                                    .font(AppFont.roll1.font)
                                    .foregroundColor(Color("B4"))
                                    .padding(.horizontal, 14)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color("W2"))
                                    )
                            }
                        }

                        // Название услуги
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Название")
                                .typography(AppFont.text)
                                .foregroundColor(Color("G3"))

                            TextField("Например: Передние стёкла", text: $title)
                                .font(AppFont.roll1.font)
                                .foregroundColor(Color("B4"))
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("W2"))
                                )
                        }

                        // Фото
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Фото")
                                .typography(AppFont.text)
                                .foregroundColor(Color("G3"))

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
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color("W2"))
                                )
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

                        // Время услуги
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Время на услугу")
                                .typography(AppFont.text)
                                .foregroundColor(Color("G3"))

                            HStack {
                                ForEach(durationOptions, id: \.self) { value in
                                    let isSelected = selectedDuration == value
                                    Text("\(value) минут")
                                        .typography(AppFont.icon)
                                        .foregroundColor(isSelected ? Color("B4") : Color("W2"))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(isSelected ? Color("W2") : Color("B1"))
                                        )
                                        .onTapGesture {
                                            selectedDuration = value
                                        }
                                }
                            }
                        }

                        // Цена
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Цена")
                                .typography(AppFont.text)
                                .foregroundColor(Color("G3"))

                            TextField("Например: от 4400 ₽", text: $priceText)
                                .font(AppFont.roll1.font)
                                .foregroundColor(Color("B4"))
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("W2"))
                                )
                        }
                    }
                    .padding(.horizontal, 21)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }


                // Кнопка удалить (только если редактируем существующую услугу)
                if onDelete != nil, initialService != nil {
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Text("Удалить услугу")
                            .typography(AppFont.roll1)
                            .foregroundColor(Color("W2"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("B3"))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 21)
                    .padding(.bottom, 16)
                    .alert("Удалить услугу?", isPresented: $showDeleteAlert) {
                        Button("Отмена", role: .cancel) {}
                        Button("Удалить", role: .destructive) {
                            onDelete?()      // <- здесь используем замыкание
                            dismiss()
                        }
                    } message: {
                        Text("Вы действительно хотите удалить эту услугу?")
                    }
                }
                // Кнопка сохранить
                Button {
                    let service = AdminService(
                        id: initialService?.id ?? UUID(),
                        category: category.trimmingCharacters(in: .whitespacesAndNewlines),
                        title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                        durationMinutes: selectedDuration,
                        priceText: priceText.trimmingCharacters(in: .whitespacesAndNewlines),
                        imageData: imageData
                    )
                    onSave(service)
                    dismiss()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(canSave ? Color("W2") : Color("G4"))

                        Text("Сохранить")
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
        .alert("Удалить услугу?",
               isPresented: $showDeleteAlert) {
            Button("Удалить", role: .destructive) {
                onDelete?()
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Вы действительно хотите удалить услугу?")
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let item = newItem else {
                imageData = nil
                return
            }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        imageData = data
                    }
                }
            }
        }
    }
}

// MARK: - Редактор мастера

struct AdminMasterEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let allCategories: [String]
    let initialMaster: AdminMaster?
    let onSave: (AdminMaster) -> Void

    @State private var name: String = ""
    @State private var selectedCategories: Set<String> = []
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?

    init(
        allCategories: [String],
        initialMaster: AdminMaster?,
        onSave: @escaping (AdminMaster) -> Void
    ) {
        self.allCategories = allCategories
        self.initialMaster = initialMaster
        self.onSave = onSave

        _name = State(initialValue: initialMaster?.name ?? "")
        _selectedCategories = State(initialValue: initialMaster?.categories ?? [])
        _imageData = State(initialValue: initialMaster?.imageData)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

                    Text(initialMaster == nil ? "Новый мастер" : "Редактор мастера")
                        .typography(AppFont.lead1)
                        .foregroundColor(Color("W2"))

                    Spacer()
                }
                .padding(.horizontal, 21)
                .padding(.top, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // Имя
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Имя мастера")
                                .typography(AppFont.text)
                                .foregroundColor(Color("G3"))

                            TextField("Например: Антон", text: $name)
                                .font(AppFont.roll1.font)
                                .foregroundColor(Color("B4"))
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("W2"))
                                )
                        }

                        // Категории
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Категории услуг")
                                .typography(AppFont.text)
                                .foregroundColor(Color("G3"))

                            if allCategories.isEmpty {
                                Text("Пока нет категорий. Добавьте хотя бы одну услугу.")
                                    .typography(AppFont.subtitle)
                                    .foregroundColor(Color("G3"))
                            } else {
                                LazyVGrid(
                                    columns: [GridItem(.adaptive(minimum: 90), spacing: 8)],
                                    spacing: 8
                                ) {
                                    ForEach(allCategories, id: \.self) { cat in
                                        let isSelected = selectedCategories.contains(cat)
                                        Text(cat)
                                            .typography(AppFont.icon)
                                            .foregroundColor(isSelected ? Color("B4") : Color("W2"))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(isSelected ? Color("W2") : Color("B1"))
                                            )
                                            .onTapGesture {
                                                if isSelected {
                                                    selectedCategories.remove(cat)
                                                } else {
                                                    selectedCategories.insert(cat)
                                                }
                                            }
                                    }
                                }
                            }
                        }

                        // Фото
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Фото")
                                .typography(AppFont.text)
                                .foregroundColor(Color("G3"))

                            PhotosPicker(
                                selection: $selectedPhoto,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 18, weight: .medium))
                                    Text(imageData == nil ? "Добавить фото" : "Изменить фото")
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

                            if let data = imageData,
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipped()
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 21)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }

                Button {
                    let master = AdminMaster(
                        id: initialMaster?.id ?? UUID(),
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        categories: selectedCategories,
                        imageData: imageData
                    )
                    onSave(master)
                    dismiss()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(canSave ? Color("W2") : Color("G4"))

                        Text("Сохранить")
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
        .onChange(of: selectedPhoto) { _, newItem in
            guard let item = newItem else {
                imageData = nil
                return
            }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        imageData = data
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdminServicesView()
    }
    .preferredColorScheme(.dark)
}
