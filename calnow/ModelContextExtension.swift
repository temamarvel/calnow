import SwiftData
import Foundation

extension ModelContext {
    func getExistedUserProfile() throws -> UserProfile? {
        let key = "UserProfileSingleton"
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.key == key },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        var items = try fetch(descriptor)
        return items.first;
    }
    
    // TODO: узнать насколько и когда адекватно применять экстеншены базовых классов
    // но надо посмотреть как это используется и тогда будет понятно насколько это хорошее решние
    // так же погуглить
    func getUserProfile() throws -> UserProfile {
        let key = "UserProfileSingleton"
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.key == key },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        var items = try fetch(descriptor)
        
        // Если по каким-то причинам оказалось >1 записи — починим:
        if items.count > 1 {
            // Сохраняем самую свежую, остальные удаляем
            let keep = items.removeFirst()
            for extra in items { delete(extra) }
            //try save()
            return keep
        }
        
        if let existing = items.first {
            return existing
        }
        
        // Нет записи — создаём
        let created = UserProfile()
        created.key = key
        insert(created)
        //try save()
        return created
    }
    
    func updateUserProfile(_ update: (UserProfile) -> Void) throws {
        if let profile = try getExistedUserProfile() {
            update(profile)
            profile.updatedAt = .now
        } else {
            let newProfile = UserProfile()                 // при необходимости задай дефолтные поля
            update(newProfile)
            newProfile.updatedAt = .now
            insert(newProfile)                // ВАЖНО: на новый объект нужен insert
        }
        try save()
    }
}
