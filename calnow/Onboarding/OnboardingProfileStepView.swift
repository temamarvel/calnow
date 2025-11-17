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

    @State private var height: Double = 0.0
    @State private var weight: Double = 0.0
    @State private var age: Int = 0
    @State private var sex: Sex = .male
    @State private var activityLevel: ActivityLevel = .moderate

    @State private var validationError: String?

    private var existingProfile: UserProfile? {
        profiles.first
    }

    var body: some View {
        Form {
            Section(header: Text("Основные параметры")) {
                TextField("Рост (см)", value: $height, format: .number)
                    .keyboardType(.numberPad)

                TextField("Вес (кг)", value: $weight, format: .number)
                    .keyboardType(.decimalPad)

                TextField("Возраст", value: $age, format: .number)
                    .keyboardType(.numberPad)

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

            if let validationError {
                Section {
                    Text(validationError)
                        .foregroundColor(.red)
                }
            }

            Section {
                Button("Сохранить профиль") {
                    saveProfile()
                }
            }
        }
        .navigationTitle("Ваш профиль")
        .onAppear {
            //preloadExistingProfileIfAny()
        }
    }
    
    private func importProfileFromHealthKit(){
        //height = healthKitManager.fetchLatestHeight()
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
        validationError = nil

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
