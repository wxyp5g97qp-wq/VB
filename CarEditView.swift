// FILE: CarEditView.swift
import SwiftUI

struct CarEditView: View {
    @EnvironmentObject var bookingFlow: BookingFlowState
    @Environment(\.dismiss) private var dismiss

    /// nil = создаём новое авто
    let car: CarItem?

    @State private var number: String
    @State private var brand: String
    @State private var model: String
    @State private var yearString: String
    @State private var bodyType: String

    // варианты кузовов
    private let bodyTypes = [
        "Седан", "Лифтбек", "Хетчбэк", "Универсал",
        "Купе", "Кроссовер", "Внедорожник"
    ]

    init(car: CarItem?) {
        self.car = car

        _number     = State(initialValue: car?.number ?? "")
        _brand      = State(initialValue: car?.brand  ?? "")
        _model      = State(initialValue: car?.model  ?? "")
        _yearString = State(initialValue: car?.year.map { String($0) } ?? "")
        _bodyType   = State(initialValue: car?.bodyType ?? "")
    }

    private var isValid: Bool {
        !number.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                header

                Group {
                    fieldTitle("Номер")
                    plateField

                    fieldTitle("Марка")
                    simpleTextField(text: $brand)

                    fieldTitle("Модель")
                    simpleTextField(text: $model)

                    fieldTitle("Год")
                    simpleTextField(text: $yearString, keyboard: .numberPad)

                    fieldTitle("Кузов")
                    bodyTypePicker
                }
                .padding(.horizontal, 21)

                Spacer()

                saveButton
            }
        }
    }

    // MARK: - UI кусочки

    private func fieldTitle(_ title: String) -> some View {
        Text(title)
            .typography(AppFont.lead3)
            .foregroundColor(Color("W2"))
    }

    private var plateField: some View {
        TextField("", text: $number)
            .font(AppFont.roll1.font)
            .foregroundColor(Color("B4"))
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("W2"))
            )
    }

    private func simpleTextField(text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField("", text: text)
            .keyboardType(keyboard)
            .font(AppFont.roll1.font)
            .foregroundColor(Color("B4"))
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("W2"))
            )
    }

    private var bodyTypePicker: some View {
        Menu {
            ForEach(bodyTypes, id: \.self) { type in
                Button(type) {
                    bodyType = type
                }
            }
        } label: {
            HStack {
                Text(bodyType.isEmpty ? "Выберите тип кузова" : bodyType)
                    .typography(AppFont.roll1)
                    .foregroundColor(bodyType.isEmpty ? Color("G3") : Color("B4"))

                Spacer()

                Image(systemName: "chevron.down")
                    .foregroundColor(Color("G3"))
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("W2"))
            )
        }
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isValid ? Color("W2") : Color("G4"))

                Text("Сохранить")
                    .typography(AppFont.lead2)
                    .foregroundColor(isValid ? Color("B4") : Color("W2"))
            }
            .frame(height: 64)
            .padding(.horizontal, 21)
            .padding(.bottom, 24)
        }
        .disabled(!isValid)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image("icon_back")
                    .renderingMode(.template)
                    .foregroundColor(Color("W2"))
            }

            Text(car == nil ? "Новое авто" : "Редактирование авто")
                .typography(AppFont.lead1)
                .foregroundColor(Color("W2"))

            Spacer()
        }
        .padding(.horizontal, 21)
        .padding(.top, 16)
    }

    // MARK: - Сохранение

    private func save() {
        let plate  = number.trimmingCharacters(in: .whitespacesAndNewlines)
        let brandT = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelT = model.trimmingCharacters(in: .whitespacesAndNewlines)
        let bodyT  = bodyType.trimmingCharacters(in: .whitespacesAndNewlines)
        let yearInt = Int(yearString.trimmingCharacters(in: .whitespacesAndNewlines))

        guard !plate.isEmpty else { return }

        if let car = car {
            // РЕДАКТИРУЕМ СУЩЕСТВУЮЩЕЕ АВТО
            bookingFlow.updateCar(
                car,
                newNumber: plate,
                newBrand: brandT,
                newModel: modelT,
                newYear: yearInt,
                newBodyType: bodyT
            )
        } else {
            // ДОБАВЛЯЕМ НОВОЕ
            bookingFlow.addCar(
                number: plate,
                brand: brandT,
                model: modelT,
                year: yearInt,
                bodyType: bodyT
            )
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        CarEditView(car: nil)
            .environmentObject(BookingFlowState())
    }
    .preferredColorScheme(.dark)
}
