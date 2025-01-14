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
    case lastStartTime = "lastStartTime"
    case lastEndTime = "lastEndTime"
    case uuid = "uuid"
}

class Storage: ObservableObject {
    static let main: Storage = Storage()
    
    @Published var lastStartTime: TimeInterval
    @Published var lastEndTime: TimeInterval
    
    var ref: DatabaseReference!
    var myID: String = Storage.string(.uuid) ?? "00000000000000000000000000000000"
    
    init() {
        ref = Database.database().reference()
        lastStartTime = Storage.getDate(of: .lastStartTime)
        lastEndTime = Storage.getDate(of: .lastEndTime)
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
                guard let otherID = dict.keys.first(where: { $0 != self.myID }) else { return }
                guard let otherStart = dict[otherID]?[Key.lastStartTime.rawValue] else { return }
                guard let otherEnd = dict[otherID]?[Key.lastEndTime.rawValue] else { return }
                if otherStart !~ self.lastStartTime {
                    if otherStart > self.lastEndTime {
                        self.lastStartTime = otherStart
                        self.lastEndTime = otherEnd
                        self.storeDates()
                    }
                } else if otherEnd !~ self.lastEndTime {
                    if otherEnd < self.lastEndTime {
                        self.lastEndTime = otherEnd
                        self.storeDate(of: .lastEndTime, self.lastEndTime)
                    }
                }
            }
        })
    }
    
    func storeDate(of key: Key, _ date: TimeInterval) {
        UserDefaults.standard.set(date, forKey: key.rawValue)
        ref.child(myID).child(key.rawValue).setValue(date)
    }
    
    func storeDates() {
        UserDefaults.standard.set(lastStartTime, forKey: Key.lastStartTime.rawValue)
        UserDefaults.standard.set(lastEndTime, forKey: Key.lastEndTime.rawValue)
        ref.child(myID).setValue([Key.lastStartTime.rawValue: lastStartTime, Key.lastEndTime.rawValue: lastEndTime])
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
    
    var cooldownEndTime: TimeInterval {
        lastEndTime + projectTime
    }
    
    var activeProject: Bool {
        return Date.now.timeIntervalSinceReferenceDate <= lastEndTime
    }
    
    var activeCooldown: Bool {
        return Date.now.timeIntervalSinceReferenceDate > lastEndTime && cooldownEndTime > Date.now.timeIntervalSinceReferenceDate
    }
    
    var projectTime: TimeInterval {
        lastEndTime - lastStartTime
    }
}

infix operator ~ : ComparisonPrecedence
infix operator !~ : ComparisonPrecedence

extension Double {
    static func ~(lhs: Double, rhs: Double) -> Bool {
        return abs(lhs - rhs) < 0.00001
    }
    
    static func !~(lhs: Double, rhs: Double) -> Bool {
        return abs(lhs - rhs) >= 0.00001
    }
}
