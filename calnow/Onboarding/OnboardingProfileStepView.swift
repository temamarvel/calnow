//
//  ProfileStep.swift
//  calnow
//
//  Created by Артем Денисов on 17.11.2025.
//


import SwiftData
import SwiftUI

struct OnboardingProfileStepView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var healthKitManager : HealthKitManager
    @Query private var profiles: [UserProfile]

    enum ProfileField: Hashable, CaseIterable {
        case height
        case weight
        case age
    }
    
    @FocusState private var focusedField: ProfileField?
    
    @State private var height: Double = 0.0
    @State private var weight: Double = 0.0
    @State private var age: Int = 0
    @State private var sex: Sex = .male
    @State private var activityLevel: ActivityLevel = .moderate

    @State private var heightValidationError: String?
    @State private var weightValidationError: String?
    @State private var ageValidationError: String?

    private var existingProfile: UserProfile? {
        profiles.first
    }

    var body: some View {
        Form {
            Section(header: Text("Основные параметры")) {
                TextField("Рост (см)", value: $height, format: .number)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(heightValidationError == nil ? Color.clear : Color.red)
                    )

                TextField("Вес (кг)", value: $weight, format: .number)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .weight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(weightValidationError == nil ? Color.clear : Color.red)
                    )
                
                TextField("Возраст", value: $age, format: .number)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .age)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ageValidationError == nil ? Color.clear : Color.red)
                    )

                Picker("Пол", selection: $sex) {
                    ForEach(Sex.allCases) { sex in
                        Text(sex.rawValue).tag(sex)
                    }
                }

                Picker("Активность", selection: $activityLevel) {
                    ForEach(ActivityLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
            }

            Section {
                Button("Сохранить профиль") {
                    saveProfile()
                }
            }
        }
        .onChange(of: focusedField) {
            validateAll()
        }
        .navigationTitle("Ваш профиль")
        .onAppear {
            //preloadExistingProfileIfAny()
            importProfileFromHealthKit()
        }
    }
    
    private func validate(field: ProfileField) {
        switch field {
            case .height:
                if height < 100 || height > 250 {
                    heightValidationError = "Рост должен быть от 100 до 250 см"
                } else {
                    heightValidationError = nil
                }
                
            case .weight:
                if weight < 40 || weight > 250 {
                    weightValidationError = "Вес должен быть от 40 до 250 кг"
                } else {
                    weightValidationError = nil
                }
                
            case .age:
                if age < 14 || age > 100 {
                    ageValidationError = "Возраст должен быть от 14 до 100 лет"
                } else {
                    ageValidationError = nil
                }
        }
    }
    
    private func validateAll() {
        for field in ProfileField.allCases {
            validate(field: field)
        }
    }
    
    private func importProfileFromHealthKit(){
        Task{
            height = try await healthKitManager.fetchLatestHeight() ?? 0.0
            weight = try await healthKitManager.fetchLatestWeight() ?? 0.0
            age = try await healthKitManager.fetchAge() ?? 0
            sex = try await healthKitManager.fetchSex() ?? .male
        }
    }

    private func preloadExistingProfileIfAny() {
        guard let profile = existingProfile else { return }

//        if let h = profile.height { heightText = String(Int(h)) }
//        if let w = profile.weight { weightText = String(format: "%.1f", w) }
//        if let a = profile.age { ageText = String(a) }
//        if let sex = profile.sex { selectedSex = sex }
//        if let lvl = profile.activity { selectedActivity = lvl }
    }

    private func saveProfile() {
        //validationError = nil

        //TODO: implement save
        
//        guard let height = Double(heightText),
//              let weight = Double(weightText),
//              let age = Int(ageText)
//        else {
//            validationError = "Заполните рост, вес и возраст корректно."
//            return
//        }
//
//        let profile = existingProfile ?? UserProfile()
//        profile.height = height
//        profile.weight = weight
//        profile.age = age
//        profile.sex = selectedSex
//        profile.activity = selectedActivity
//        //profile.isCompleted = true   // <- важный флаг
//
//        if existingProfile == nil {
//            context.insert(profile)
//        }
//
//        do {
//            try context.save()
//            //onFinished()
//        } catch {
//            validationError = "Не удалось сохранить профиль: \(error.localizedDescription)"
//        }
    }
}
