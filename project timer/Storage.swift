//
//  Storage.swift
//  project timer
//
//  Created by 4 on '24.12.8.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseDatabase

enum Key: String {
    case projectStart = "projectStart"
    case consumeStart = "consumeStart"
    case projectEnd = "projectEnd"
    case consumeEnd = "consumeEnd"
    case projectRatio = "projectRatio"
    case consumeRatio = "consumeRatio"
    case updated = "updated"
    case project = "project"
    case uuid = "uuid"
}

class Storage: ObservableObject {
    static let main: Storage = Storage()
    
    @Published var projectStart: TimeInterval
    @Published var consumeStart: TimeInterval
    @Published var projectEnd: TimeInterval
    @Published var consumeEnd: TimeInterval
    var projectRatio: Double
    var consumeRatio: Double
    var updated: TimeInterval
    
    var ref: DatabaseReference!
    var myID: String = Storage.string(.uuid) ?? "00000000000000000000000000000000"
    
    init() {
        ref = Database.database().reference()
        projectStart = Storage.getDate(of: .projectStart)
        consumeStart = Storage.getDate(of: .consumeStart)
        projectEnd = Storage.getDate(of: .projectEnd)
        consumeEnd = Storage.getDate(of: .consumeEnd)
        projectRatio = Storage.getDouble(for: .projectRatio)
        consumeRatio = Storage.getDouble(for: .consumeRatio)
        updated = Storage.getDouble(for: .updated)
        
        if projectRatio == 0 { projectRatio = 2.0 }
        if consumeRatio == 0 { consumeRatio = 4.0 }
        
        _ = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                Storage.set(user.uid, for: .uuid)
                self.myID = user.uid
            } else {
                // should only happen once, when i first use the app
                Auth.auth().signInAnonymously() { (authResult, error) in
                    if let error = error {
                        print("Sign in error:", error)
                    }
                }
            }
        }
        _ = ref.observe(DataEventType.value, with: { snapshot in
            if let dict = snapshot.value as? [String: [String: Double]] {
                guard let newDict = dict.first(where: { $0.key != self.myID })?.value else { return }
                if let newProjectRatio = newDict[Key.projectRatio.rawValue], newProjectRatio != self.projectRatio {
                    self.projectRatio = newProjectRatio
                    Storage.set(self.projectRatio, for: .projectRatio)
                }
                if let newConsumeRatio = newDict[Key.consumeRatio.rawValue], newConsumeRatio != self.consumeRatio {
                    self.consumeRatio = newConsumeRatio
                    Storage.set(self.consumeRatio, for: .consumeRatio)
                }
                if newDict[Key.updated.rawValue] ?? 0 ~>= self.updated {
                    self.updated = (newDict[Key.updated.rawValue] ?? 0) + 0.001
                    Storage.set(self.updated, for: .updated)
                    self.ref.child(self.myID).removeValue()
                    let oldce = self.consumeEnd
                    self.projectStart = newDict[Key.projectStart.rawValue] ?? 0
                    self.projectEnd = newDict[Key.projectEnd.rawValue] ?? 0
                    self.consumeStart = newDict[Key.consumeStart.rawValue] ?? 0
                    self.consumeEnd = newDict[Key.consumeEnd.rawValue] ?? 0
                    print("from 4: changed consume end from", oldce, "to", self.consumeEnd, "based on update#", self.updated)
                }
            }
        })
    }
    
    func storeDate(of key: Key, _ date: TimeInterval) {
        UserDefaults.standard.set(date, forKey: key.rawValue)
        ref.child(myID).child(key.rawValue).setValue(date)
        updated = Date.now.timeIntervalSinceReferenceDate
        Storage.set(updated, for: .updated)
        ref.child(myID).child(Key.updated.rawValue).setValue(updated)
        if key == .consumeEnd {
            print("just posted update", consumeEnd, "update#", updated)
        }
    }
    
    func storeProjectDates() {
        UserDefaults.standard.set(projectStart, forKey: Key.projectStart.rawValue)
        UserDefaults.standard.set(projectEnd, forKey: Key.projectEnd.rawValue)
        ref.child(myID).child(Key.projectStart.rawValue).setValue(projectStart)
        ref.child(myID).child(Key.projectEnd.rawValue).setValue(projectEnd)
        updated = Date.now.timeIntervalSinceReferenceDate
        Storage.set(updated, for: .updated)
        ref.child(myID).child(Key.updated.rawValue).setValue(updated)
    }
    
    func storeConsumeDates() {
        UserDefaults.standard.set(consumeStart, forKey: Key.consumeStart.rawValue)
        UserDefaults.standard.set(consumeEnd, forKey: Key.consumeEnd.rawValue)
        ref.child(myID).child(Key.consumeStart.rawValue).setValue(consumeStart)
        ref.child(myID).child(Key.consumeEnd.rawValue).setValue(consumeEnd)
        updated = Date.now.timeIntervalSinceReferenceDate
        Storage.set(updated, for: .updated)
        ref.child(myID).child(Key.updated.rawValue).setValue(updated)
    }
    
    static func set(_ value: Any?, for key: Key) {
        UserDefaults.standard.setValue(value, forKey: key.rawValue)
    }
    
    static func string(_ key: Key) -> String? {
        UserDefaults.standard.string(forKey: key.rawValue)
    }
    
    private static func getDate(of key: Key) -> TimeInterval {
        getDouble(for: key)
    }
    private static func getDouble(for key: Key) -> Double {
        UserDefaults.standard.double(forKey: key.rawValue)
    }
    
    static func bool(_ key: Key) -> Bool {
        UserDefaults.standard.bool(forKey: key.rawValue)
    }
    
    var projectTime: TimeInterval {
        projectEnd - projectStart
    }
    
    var projectActive: Bool {
        return Date.now.timeIntervalSinceReferenceDate <= projectEnd
    }
    
    var projectCooldownEnd: TimeInterval {
        projectEnd + projectRatio*projectTime
    }
    
    var projectCooldown: Bool {
        return Date.now.timeIntervalSinceReferenceDate > projectEnd && projectCooldownEnd > Date.now.timeIntervalSinceReferenceDate
    }
    
    var consumeTime: TimeInterval {
        consumeEnd - consumeStart
    }
    
    var consumeActive: Bool {
        return Date.now.timeIntervalSinceReferenceDate <= consumeEnd
    }
    
    var consumeCooldownEnd: TimeInterval {
        consumeEnd + consumeRatio*consumeTime
    }
    
    var consumeCooldown: Bool {
        return Date.now.timeIntervalSinceReferenceDate > consumeEnd && consumeCooldownEnd > Date.now.timeIntervalSinceReferenceDate
    }
}

infix operator ~ : ComparisonPrecedence
infix operator !~ : ComparisonPrecedence
infix operator ~> : ComparisonPrecedence
infix operator ~>= : ComparisonPrecedence
infix operator ~< : ComparisonPrecedence
infix operator ~<= : ComparisonPrecedence

extension Double {
    static func ~(lhs: Double, rhs: Double) -> Bool {
        return abs(lhs - rhs) < 0.00001
    }
    
    static func !~(lhs: Double, rhs: Double) -> Bool {
        return abs(lhs - rhs) >= 0.00001
    }
    
    static func ~>(lhs: Double, rhs: Double) -> Bool {
        return lhs > rhs + 0.00001
    }
    
    static func ~>=(lhs: Double, rhs: Double) -> Bool {
        return lhs + 0.00001 > rhs
    }
    
    static func ~<(lhs: Double, rhs: Double) -> Bool {
        return lhs + 0.00001 < rhs
    }
    
    static func ~<=(lhs: Double, rhs: Double) -> Bool {
        return lhs < rhs + 0.00001
    }
}
