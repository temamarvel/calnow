import SwiftData
import Foundation

enum Sex: String, Codable, CaseIterable, Identifiable {
    case male = "Мужской"
    case female = "Женский"
    var id: String { rawValue }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary = "Минимальная активность"
    case light = "Лёгкая (1–3 трен/нед)"
    case moderate = "Средняя (3–5)"
    case high = "Высокая (6–7)"
    case athlete = "Очень высокая"
    var id: String { rawValue }
    
    var multiplier: Double {
        switch self {
            case .sedentary: return 1.2
            case .light:     return 1.375
            case .moderate:  return 1.55
            case .high:      return 1.725
            case .athlete:   return 1.9
        }
    }
}

@Model
final class UserProfile {
    
    var key: String = "UserProfileSingleton"
    
    // Данные профиля
    var sex: Sex
    var age: Int
    var height: Double
    var weight: Double
    var activity: ActivityLevel
    
    // Метаданные (удобно для отладки/синхронизации)
    var createdAt: Date
    var updatedAt: Date
    
    init(
        sex: Sex = .male,
        age: Int = 30,
        height: Double = 175,
        weight: Double = 75,
        activity: ActivityLevel = .moderate,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.sex = sex
        self.age = age
        self.height = height
        self.weight = weight
        self.activity = activity
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // BMR по Миффлину—Сан Жеору
    var bmr: Double {
        let base = 10.0*(weight) + 6.25*(height) - 5.0*Double(age)
        return sex == .male ? (base + 5.0) : (base - 161.0)
    }
    
    // Пример TDEE
    var tdee: Double { bmr * (activity.multiplier) }
}
