//
//  ProfileView.swift
//  calnow
//
//  Created by Артем Денисов on 05.01.2026.
//

import SwiftUI
import SwiftData
import HealthKitDataService

// MARK: - Draft

struct UserProfileDraft: Equatable {
    var sex: Sex
    var age: Int
    var height: Double
    var weight: Double
    var activity: ActivityLevel
    
    init(
        sex: Sex = .male,
        age: Int = 30,
        height: Double = 170.0,
        weight: Double = 80.0,
        activity: ActivityLevel = .moderate
    ) {
        self.sex = sex
        self.age = age
        self.height = height
        self.weight = weight
        self.activity = activity
    }
    
    init(from profile: UserProfile) {
        self.sex = profile.sex
        self.age = profile.age
        self.height = profile.height
        self.weight = profile.weight
        self.activity = profile.activity
    }
    
    // BMR по Миффлину—Сан Жеору
    var bmr: Double {
        let base = 10.0 * weight + 6.25 * height - 5.0 * Double(age)
        return sex == .male ? (base + 5.0) : (base - 161.0)
    }
    
    // TDEE
    var tdee: Double { bmr * activity.multiplier }
    
    var isValid: Bool {
        (10...100).contains(age)
        && (120...230).contains(height)
        && (30...250).contains(weight)
    }
}

// MARK: - View

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var profiles: [UserProfile]
    
    private var profile: UserProfile? { profiles.first }
    
    // Draft НЕ optional
    @State private var draft = UserProfileDraft()
    @State private var isLoaded = false
    
    @State private var errorMessage: String?
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack{
            Form {
                Section("Данные профиля") {
                    if isLoaded {
                        Picker("Пол", selection: $draft.sex) {
                            ForEach(Sex.allCases) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        
                        Stepper(value: $draft.age, in: 5...100, step: 1) {
                            HStack {
                                Text("Возраст")
                                Spacer()
                                Text("\(draft.age)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Stepper(value: $draft.height, in: 120...230, step: 1) {
                            HStack {
                                Text("Рост")
                                Spacer()
                                Text("\(Int(draft.height)) см")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Stepper(value: $draft.weight, in: 30...250, step: 0.5) {
                            HStack {
                                Text("Вес")
                                Spacer()
                                Text(String(format: "%.1f кг", draft.weight))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Picker("Активность", selection: $draft.activity) {
                            ForEach(ActivityLevel.allCases) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                    } else {
                        ProgressView("Загрузка…")
                    }
                }
                
                Section("Расчёты") {
                    if isLoaded {
                        LabeledContent("BMR") { Text("\(Int(draft.bmr)) ккал") }
                        LabeledContent("TDEE") { Text("\(Int(draft.tdee)) ккал") }
                    } else {
                        Text("—").foregroundStyle(.secondary)
                    }
                }
                
                if let msg = validationMessage {
                    Section { Text(msg).foregroundStyle(.red) }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Профиль")
            .appBackground()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Сброс") {
                        loadDraft()
                    }
                    .disabled(!isLoaded || isSaving)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Сохранить")
                        }
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                loadDraft()
            }
        }
    }
    
    private var validationMessage: String? {
        if profile == nil { return "Профиль не найден." }
        if !isLoaded { return "Черновик профиля не найден." }
        if !draft.isValid { return "Проверь введённые значения." }
        if isSaving { return "Идет сохранение данных профиля." }
        return nil
    }
    
    // MARK: - Derived state
    
    private var canSave: Bool {
        guard validationMessage == nil else { return false }
        
        // Активируем кнопку только если есть изменения
        if let profile {
            return draft != UserProfileDraft(from: profile)
        }
        return false
    }
    
    // MARK: - Data
    
    private func loadDraft() {
        guard let profile else {
            errorMessage = "Профиль не найден."
            return
        }
        draft = UserProfileDraft(from: profile)
        isLoaded = true
        errorMessage = nil
    }
    
    private func save() {
        guard let profile else {
            errorMessage = "Профиль не найден."
            return
        }
        guard isLoaded else {
            errorMessage = "Черновик профиля не найден."
            return
        }
        guard draft.isValid else {
            errorMessage = "Проверь введённые значения."
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        errorMessage = nil
        
        profile.update(with: draft)
        
        do {
            try modelContext.save()
            // Перезагрузим draft из сохранённой модели, чтобы гарантировать консистентность
            self.draft = UserProfileDraft(from: profile)
        } catch {
            errorMessage = "Не удалось сохранить: \(error.localizedDescription)"
        }
    }
}

struct ProfileViewPreviewWrapper: View {
    let container: ModelContainer
    @StateObject private var healthService = HealthKitDataService()
    
    init() {
        // in-memory контейнер
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: UserProfile.self, configurations: config)
        
        let context = container.mainContext
        
        // тестовый профиль — подгони под свою модель
        let profile = UserProfile()
        //        profile.bmr = 1700
        //        profile.tdee = 2600
        context.insert(profile)
    }
    
    var body: some View {
        ProfileView()
            .modelContainer(container)
            .environmentObject(healthService)
    }
}

#Preview {
    ProfileViewPreviewWrapper()
}
