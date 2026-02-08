//
//  Persistence.swift
//  Luna - 3AM Companion
//
//  This file is no longer used - the app uses SwiftData instead of Core Data.
//  Keeping for legacy reference only.
//

import CoreData
import os.log

private let persistenceLogger = Logger(subsystem: "com.luna.companion", category: "Persistence")

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Luna___3AM_Companion")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                persistenceLogger.error("Core Data error: \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
